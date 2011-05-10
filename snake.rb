require "rubygems"
require "rubygame"
include Rubygame


Surface.autoload_dirs = [ File.dirname(__FILE__) ]

@@screen_width = 470
@@screen_height = 290

#Sprites::Group - extends the RubyGame class so we don't have to define a new class with a reference to Group
class Sprites::Group
	
	@@motion_distance =5
	
	###returns lambda that can be passed to segments of the snake so they know when to turn
	def should_turn()
		x = snake_head.rect.x
		y = snake_head.rect.y
		lambda {|rect|  if x == rect.x and y == rect.y  then true else false end}		
	end

	def add_next_tail?()
		x = last_segment.get_coord(last_segment.vx, last_segment.rect.x)
		y = last_segment.get_coord(last_segment.vy, last_segment.rect.y)
		lambda {|rect| if x == rect.x and y == rect.y  then true else false end}		
	end
	
	def add_next_tail_test?()
		x = last_segment.get_coord(last_segment.vx, last_segment.rect.x)
		y = last_segment.get_coord(last_segment.vy, last_segment.rect.y)
		lambda {|rect| if x == rect.x and y == rect.y  then true else false end}
		#lambda {|rect| puts "last_x: #{x}, new_x #{rect.x} last_y: #{y}, new_y #{rect.y}"}
	end

	def add_head
		segment = Head.new
		self<<(segment)
		#safe to set @tails_to_add to zero here because we only add the head once.
		@tails_to_add = 0
		@next_tail = nil
		3.times {add_tail}
	end
	
	def add_tail
		@tails_to_add = @tails_to_add + 1
		@next_tail = add_next_tail?()
		@next_tail_test = add_next_tail_test?()

	end
	
	#Food is the first sprite in the list
	def food
		self[0]
	end
	
	#Snake head is always the 2nd Sprite after Food
	def snake_head
		self[1]
	end
	
	#The tail is all the sprites from the 2nd Sprite (after the Food)
	def snake_segments
		self[1..-1]
	end
	
	def last_segment
		self[self.length-1]
	end
	
	def add_turns_to_segments(x,y,angle)
		turn = Turn.new(x, y,angle,should_turn())
		snake_segments.each{ |i| i.add_turn(turn) }
	end
		
	
	def turn_left
		add_turns_to_segments(-@@motion_distance,0,90)
	end	
	
	def turn_right
		add_turns_to_segments(@@motion_distance,0,270)
	end	
	
	def turn_up
		add_turns_to_segments(0,-@@motion_distance,0)
	end
	
	def turn_down
		add_turns_to_segments(0,@@motion_distance,180)
	end
	
	def off
		self[1..-1].each { |i| i.off }
	end
	
	def has_eaten_food?()
		1.times {add_tail} if snake_head.has_eaten_food?(food.rect)
	end
	
	def has_gone_off_screen?()
		return true if snake_head.rect.x < 0
		return true if snake_head.rect.y < 0
		return true if snake_head.rect.x > (@@screen_width-30)
		return true if snake_head.rect.y > (@@screen_height-30)
	end
	
	def has_eaten_itself?()
		
		if self.length > 3
			self[3..-1].each{|x| return true if x.has_collided?(snake_head.rect)}
		end
		return false
	end	
	
	def check_tails
		if @tails_to_add > 0
			#puts "tails to add = #{@tails_to_add}"
			@next_tail_test.call(last_segment.rect) 
			if @next_tail.call(last_segment.rect)
				segment = Tail.new(last_segment)
				self<<(segment)
				@tails_to_add = @tails_to_add - 1
				@next_tail = add_next_tail?()
			end
		
		end
	end
	
end

class Segment
	include Sprites::Sprite
	
	@@motion_distance =5
	@@image_width =30
	
	attr_accessor :vx, :vy, :turns, :rect

	def initialize(x=0,y=0)	
		super()
		@original = Surface.load('snake_d_y.gif')
		@image = @original
		@rect = Rect.new(x,y,*@original.size)		
		@vx =5
		@vy = 0
		@directions = Array.new	
		@turns = []		
	end	
	
	def turn(x,y)
		@vx = x
		@vy = y
	end
		
	def off
		@vy = 0
		@vx = 0
	end
	
	def add_turn(turn)
		@turns << turn
	end
		
	def update
		
		if @turns.length > 0
			next_turn = @turns[0]
			if  next_turn.should_turn.call(@rect) 
				turn(next_turn.new_x,next_turn.new_y)
				rotate_image (next_turn.angle)
				@turns.delete_at(0)			
			end
		end

		@rect.move!(@vx,@vy)
	end	
	
	def has_eaten_food?(rect)
		false
	end
	
	def rotate_image (angle)
	end
	
	def has_collided?(rect)
		#return true
		@rect.inflate(-15, -15).collide_rect?(rect)
	end
	
	def get_coord(current_direction, current_coord)
		#get co-ordinate of new tail. Work out depending on whether previous tail motion (current_direction) was moving or not (@@motion_distance or 0)
		#and based on coord of previous tail (current_coord)
		case current_direction
			  when 0: new_coord=current_coord #not moving in this direction so co-ord is the same
			  when @@motion_distance: new_coord=current_coord + @@image_width #is moving in down or right direction so subtract the image width from the coord
			  when -@@motion_distance:  new_coord=current_coord - @@image_width #is moving in the up or left direction  so add image width from  the coord
		  end 
		  return new_coord
	end
	
end

class Head < Segment
	def initialize()			
		super()				
	end
	
	#has circle collided with the food
	def has_eaten_food?(rect)
		@rect.inflate(-15, -15).collide_rect?(rect)
	end
	
	##Sets image back to original one and then rotates
	def rotate_image (angle)
		@image = @original
		@image = @image.rotozoom(angle, 1)
	end

end

class Tail < Segment
	
	def initialize(segment)

		x = get_coord2(segment.vx, segment.rect.x)
		y = get_coord2(segment.vy, segment.rect.y)
		super(x,y)
		
		#set motion of tail
		@vx = segment.vx
		@vy = segment.vy
		
		@turns = Array.new(segment.turns)
	end
	
	def get_coord2(current_direction, current_coord)
		#get co-ordinate of new tail. Work out depending on whether previous tail motion (current_direction) was moving or not (@@motion_distance or 0)
		#and based on coord of previous tail (current_coord)
		case current_direction
			  when 0: new_coord=current_coord #not moving in this direction so co-ord is the same
			  when @@motion_distance: new_coord=current_coord - @@image_width #is moving in down or right direction so subtract the image width from the coord
			  when -@@motion_distance:  new_coord=current_coord + @@image_width #is moving in the up or left direction  so add image width from  the coord
		  end 
		  return new_coord
	end
	
end

class Turn

	attr_accessor :new_x, :new_y, :angle, :should_turn
	def initialize(new_x, new_y, angle, should_turn)
		@new_x, @new_y, @angle, @should_turn = new_x, new_y, angle, should_turn
	end

end


class Food
	
	include Sprites::Sprite
	attr_accessor :rect
	def initialize
		super()
		@image = Surface.new([8,8])
		@image.draw_ellipse_s([4,4], [4,2], [255,0,0])
		@rect = Rect.new(new_x,new_y,*@image.size)
	end
	
	def new_x
		rand(@@screen_width-40)
	end
	
	def new_y
		rand(@@screen_height-40)
	end
	
	def reset_rect
		@rect.x = 20
		@rect.y = 20
	end
	
	
	def move!
		reset_rect
		@rect.move!(new_x,new_y)
	end
	
	def update
	end
	
end

def main

	food = Food.new

	screen = Screen.set_mode([@@screen_width,@@screen_height])
	bgMain = Surface.new(screen.size)
	bgMain.fill([255,255,153])
	bgMain.blit(screen,[5,0])
	screen.update()


	allsprites = Sprites::Group.new()
	allsprites<<(food)
	allsprites.add_head
	
	frame_rate = 30
	tail_len_before_increase = 12


	clock = Clock.new { |clock| clock.target_framerate = frame_rate }
	queue = EventQueue.new() 
	catch(:rubygame_quit) do
		loop do
			clock.tick()
			queue.each do |event|
				case event
					when KeyDownEvent
						case event.key 
							when K_UP
								allsprites.turn_up
							when K_DOWN
								allsprites.turn_down
							when K_LEFT
								allsprites.turn_left
							when K_RIGHT
								allsprites.turn_right
							when K_Q
								throw :rubygame_quit 
							when K_P
								snake.off
						end
					when QuitEvent
						throw :rubygame_quit 
				end
			end
			
			if  allsprites.snake_segments.length >= tail_len_before_increase
				tail_len_before_increase = tail_len_before_increase + 5 #length extra tail can get before we increase the speed again
				frame_rate = frame_rate + 1
				puts "faster! faster!"
			end
			
			food.move! if allsprites.has_eaten_food?()
			
			if allsprites.has_gone_off_screen?()
				Rubygame::TTF.setup()
				font = TTF.new("FreeSans.ttf",15)
				text = font.render("Game Over - Gone Off Screen (Q to Quit). Length: #{allsprites.snake_segments.length}", true, [10,10,10])
				textpos = text.make_rect()
				textpos.centerx = bgMain.width/2
				# ATTENTION: Note that the "actor" is reversed from the pygame usage.
				# In pygame, a surface "pulls" another surface's data onto itself.
				# In Rubygame, a surface "pushes" its own data onto another surface.
				text.blit(bgMain,textpos)
				allsprites.off
				#throw :rubygame_quit 
			end
			
			if allsprites.has_eaten_itself?()
				Rubygame::TTF.setup()
				font = TTF.new("FreeSans.ttf",15)
				text = font.render("Game Over - Eaten Yourself (Q to Quit) Length: #{allsprites.snake_segments.length}", true, [10,10,10])
				textpos = text.make_rect()
				textpos.centerx = bgMain.width/2
				# ATTENTION: Note that the "actor" is reversed from the pygame usage.
				# In pygame, a surface "pulls" another surface's data onto itself.
				# In Rubygame, a surface "pushes" its own data onto another surface.
				text.blit(bgMain,textpos)
				allsprites.off
				#throw :rubygame_quit 
			end

			
			allsprites.check_tails
			
			allsprites.update()
			

			#Draw Everything
			bgMain.blit(screen, [0, 0])
			allsprites.draw(screen)
			screen.update()
			
		end
	end
end

#this calls the 'main' function when this script is executed
if $0 == __FILE__
	main()
end
