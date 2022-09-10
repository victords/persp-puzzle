require_relative 'constants'

include MiniGL

class Man < GameObject
  MOVE_FORCE = 0.3
  FRICTION = 0.1
  JUMP_FORCE = 8
  WIDTH = 12
  HEIGHT = 35
  MAX_SPEED_F = 3
  MAX_SPEED_T = 2
  MAX_SPEED_T_DIAG = MAX_SPEED_T * 0.5 * Math.sqrt(2)

  def initialize(x, y, z)
    super(x, y, WIDTH, HEIGHT, :sprite_man, Vector.new(-1, -5), 3, 3)
    @max_speed = Vector.new(MAX_SPEED_F, 12)

    @front_y = y
    @z = z
    @front = true
    @angle = nil
    @facing_right = true
  end

  def start_toggle
    @angle = nil unless @front
    @phys_y = @y
    @toggling = true
  end

  def toggle_view
    @front = !@front
    if @front
      @h = HEIGHT
      @phys_y = @front_y
      @angle = nil
      @img_gap.y = -5
      set_animation(0)
    else
      @h = WIDTH
      @phys_y = @z
      @angle = @facing_right ? 0 : 180
      @img_gap.y = -14
      set_animation(6)
    end
  end

  def end_toggle(screen)
    if (obst = screen.obstacles.find { |o| o.bounds.intersect?(bounds) })
      screen.toggle_view_blocked(obst)
      return
    end

    @y = @phys_y
    @toggling = false
  end

  def update(screen)
    return if @toggling

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

      @front_y = @y
    else
      up = KB.key_down?(Gosu::KB_UP)
      dn = KB.key_down?(Gosu::KB_DOWN)
      lf = KB.key_down?(Gosu::KB_LEFT)
      rt = KB.key_down?(Gosu::KB_RIGHT)

      forces, @angle =
        if up && !dn && !lf && !rt
          [Vector.new(0, -MAX_SPEED_T), -90]
        elsif dn && !up && !lf && !rt
          [Vector.new(0, MAX_SPEED_T), 90]
        elsif lf && !up && !dn && !rt
          [Vector.new(-MAX_SPEED_T, 0), 180]
        elsif rt && !up && !dn && !lf
          [Vector.new(MAX_SPEED_T, 0), 0]
        elsif up && lf && !dn && !rt
          [Vector.new(-MAX_SPEED_T_DIAG, -MAX_SPEED_T_DIAG), -135]
        elsif up && rt && !dn && !lf
          [Vector.new(MAX_SPEED_T_DIAG, -MAX_SPEED_T_DIAG), -45]
        elsif dn && lf && !up && !rt
          [Vector.new(-MAX_SPEED_T_DIAG, MAX_SPEED_T_DIAG), 135]
        elsif dn && rt && !up && !lf
          [Vector.new(MAX_SPEED_T_DIAG, MAX_SPEED_T_DIAG), 45]
        else
          [Vector.new, @angle]
        end

      move(forces, screen.obstacles, [], true)
      if @speed.x == 0 && @speed.y == 0
        set_animation(6)
      else
        animate([6, 7, 6, 8], 7)
      end

      @z = @y
    end
  end

  def draw(offset_y, scale_y)
    @y = offset_y + scale_y * @phys_y if @toggling
    super(nil, 1, scale_y, 255, 0xffffff, @angle, !@front || @facing_right ? nil : :horiz, 100)
  end
end
