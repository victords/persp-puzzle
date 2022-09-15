require_relative 'base'

class Switch < Base
  def initialize(x, y, args, front = true)
    y_offset = front ? 17 : 2
    super(0, args, x + 2, y + y_offset, 16, front ? 3 : 16, :sprite_switch, Vector.new(-2, -y_offset), 3, 1)
    @front = front
    @img_index = front ? 0 : 2
  end

  def update(man)
    man_intersects = man.bounds.intersect?(bounds)
    if man_intersects && !@pressed
      puts "pressed"
      @img_index = 1 if @front
      @pressed = true
    elsif @pressed && !man_intersects
      puts 'released'
      @img_index = 0 if @front
      @pressed = false
    end
  end
end
