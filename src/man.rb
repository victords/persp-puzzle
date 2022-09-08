require_relative 'constants'

include MiniGL

class Man < GameObject
  MOVE_FORCE = 0.3
  FRICTION = 0.1
  JUMP_FORCE = 10

  def initialize(x, y, z)
    super(x, y, MAN_SIZE, MAN_SIZE, :sprite_man, Vector.new(-2, -2), 3, 2)
    @max_speed = Vector.new(3, 12)

    @z = 0
    @front = true
  end

  def update(screen)
    if @front
      forces = Vector.new
      if KB.key_down?(Gosu::KB_RIGHT)
        forces.x += MOVE_FORCE
      elsif @speed.x > 0
        forces.x -= FRICTION
      end
      if KB.key_down?(Gosu::KB_LEFT)
        forces.x -= MOVE_FORCE
      elsif @speed.x < 0
        forces.x += FRICTION
      end
      if @bottom
        forces.y -= JUMP_FORCE if KB.key_pressed?(Gosu::KB_UP)
      end

      move(forces, screen.obstacles, [])

      if @speed.x.abs > 0.1
        animate([2, 3, 2, 4], 7)
      else
        animate([0, 1], 10)
      end
    end
  end

  def draw(scale_y)
    super(nil, 1, scale_y, 255, 0xffffff, nil, @speed.x < 0 ? :horiz : nil)
  end
end
