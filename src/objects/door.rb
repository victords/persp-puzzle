require_relative 'base'

class Door < Base
  def initialize(x, y, args, _front = true)
    super(1, args, x + 9, y + 19, 2, 1, :sprite_door, Vector.new(-9, -39), 3, 1)
  end

  def update(man)
    if @open
      animate_once([0, 1, 2], 10) do
        @open = 2
      end
    end
    return unless man.bounds.intersect?(bounds)

    if @open == 2
      # transport
    elsif KB.key_pressed?(Gosu::KB_UP) && !@open
      @open = 1
    end
  end
end
