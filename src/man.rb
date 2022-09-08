require_relative 'constants'

include MiniGL

class Man < GameObject
  MOVE_FORCE = 0.3
  FRICTION = 0.1
  JUMP_FORCE = 8
  WIDTH = 16
  HEIGHT = 35

  def initialize(x, y, z)
    super(x, y, WIDTH, HEIGHT, :sprite_man, Vector.new(-2, -5), 3, 2)
    @max_speed = Vector.new(3, 12)

    @z = 0
    @front = true
    @facing_right = true
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

      prev_bottom = @bottom
      move(forces, screen.obstacles, [])
      moving = @speed.x.abs > 0.1
      if @bottom && !prev_bottom
        set_animation(moving ? 2 : 0)
      elsif prev_bottom && !@bottom
        set_animation(5)
      end

      if @bottom
        if @speed.x.abs > 0.1
          animate([2, 3, 2, 4], 7)
        else
          animate([0, 1], 10)
        end
      end

      if @facing_right && @speed.x < 0
        @facing_right = false
      elsif !@facing_right && @speed.x > 0
        @facing_right = true
      end
    end
  end

  def draw(scale_y)
    super(nil, 1, scale_y, 255, 0xffffff, nil, @facing_right ? nil : :horiz)
  end
end
