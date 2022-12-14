require_relative 'constants'
require_relative 'man'
require_relative 'objects/_'

include MiniGL

class DepthBlock < Block
  attr_reader :depth

  def initialize(x, y, w, h, passable, depth)
    super(x, y, w, h, passable)
    @depth = depth
  end
end

class Entrance
  attr_reader :col, :row, :x, :y, :dir

  def initialize(i, j, front = true)
    @col = i
    @row = j
    @x = i * TILE_SIZE + TILE_SIZE / 2
    @y = j * TILE_SIZE + (front ? TILE_SIZE : TILE_SIZE / 2)
    @dir = if j == TILE_Y_COUNT - 1
             0
           elsif i == 0
             1
           elsif j == 0
             2
           else
             3
           end
  end
end

class Exit
  attr_reader :col, :row, :bounds, :dest_scr, :dest_ent

  def initialize(i, j, dest_scr, dest_ent)
    @col = i
    @row = j
    x = i * TILE_SIZE
    x += TILE_SIZE - 1 if i == TILE_X_COUNT - 1
    y = j * TILE_SIZE
    y += TILE_SIZE - 1 if j == TILE_Y_COUNT - 1
    w = i == 0 || i == TILE_X_COUNT - 1 ? 1 : TILE_SIZE
    h = j == 0 || j == TILE_Y_COUNT - 1 ? 1 : TILE_SIZE
    @bounds = Rectangle.new(x, y, w, h)

    @dest_scr = dest_scr
    @dest_ent = dest_ent
  end
end

class Screen
  TOGGLE_RATE = Math::PI / 60
  TRANSITION_RATE = 10
  BLOCKER_T1 = 10
  BLOCKER_T2 = 50
  OBJECT_TYPES = [
    Switch,
    Door,
  ].freeze

  def initialize(name, entrance_index = 0, from_transition = false)
    @bg = Res.img(:bg_1)

    @tileset = Res.tileset('1', TILE_SIZE, TILE_SIZE)

    @tiles_f = Array.new(32) { Array.new(18) }
    @obstacles_f = []
    @entrances_f = []
    @exits_f = []
    @objects_f = []

    @tiles_t = Array.new(32) { Array.new(18) { [] } }
    @obstacles_t = []
    @entrances_t = []
    @exits_t = []
    @objects_t = []

    @front = true
    @scale_y = 1
    @max_depth = 0
    @overlay_alpha = from_transition ? 255 : 0
    return unless name

    File.open("#{Res.prefix}screen/#{name}.txt") do |f|
      tiles_f, obst_f, ent_f, exit_f, obj_f, tiles_t, obst_t, ent_t, exit_t, obj_t =
        f.read.split('|', -1).map { |s| s.split(';') }

      i = 0; j = 0
      tiles_f.each do |d|
        if d[0] == '_'
          count = d[1..].to_i
          i, j = skip_tiles(i, j, count)
        elsif d.index('*')
          tile = d.to_i
          count = d.split('*')[1].to_i
          count.times { i, j = set_tile(@tiles_f, tile, i, j) }
        else
          i, j = set_tile(@tiles_f, d.to_i, i, j)
        end
      end
      obst_f.each do |obs|
        bounds, depth = obs.split(':')
        @obstacles_f << DepthBlock.new(*bounds.split(',').map { |s| s.to_i * TILE_SIZE }, obs.end_with?('!'), depth.to_i)
      end
      @entrances_f = ent_f.map { |e| Entrance.new(*e.split(',').map(&:to_i)) }
      @exits_f = exit_f.map { |e| Exit.new(*e.split(',').map(&:to_i)) }
      @objects_f = obj_f.map do |o|
        data, args = o.split(':')
        type, i, j = data.split(',').map(&:to_i)
        OBJECT_TYPES[type].new(i * TILE_SIZE, j * TILE_SIZE, args)
      end

      i = 0; j = 0
      tiles_t.each do |d|
        if d[0] == '_'
          count = d[1..].to_i
          i, j = skip_tiles(i, j, count)
        elsif d.index('*')
          tile = d.to_i
          depth, count = d.split(':')[1].split('*').map(&:to_i)
          count.times { i, j = set_tile(@tiles_t, [[tile, depth]], i, j) }
          @max_depth = depth if depth > @max_depth
        else
          tiles = []
          d.split(',').each_with_index do |t|
            tile, depth = t.split(':').map(&:to_i)
            tiles << [tile, depth]
            @max_depth = depth if depth > @max_depth
          end
          i, j = set_tile(@tiles_t, tiles, i, j)
        end
      end
      obst_t.each do |obs|
        bounds, depth = obs.split(':')
        depth = depth.to_i
        @obstacles_t[depth] ||= []
        @obstacles_t[depth] << Block.new(*bounds.split(',').map { |s| s.to_i * TILE_SIZE })
      end
      @entrances_t = ent_t.map { |e| Entrance.new(*e.split(',').map(&:to_i), false) }
      @exits_t = exit_t.map { |e| Exit.new(*e.split(',').map(&:to_i)) }
      @objects_t = obj_t.map do |o|
        data, args = o.split(':')
        type, i, j = data.split(',').map(&:to_i)
        OBJECT_TYPES[type].new(i * TILE_SIZE, j * TILE_SIZE, args, false)
      end
    end

    @man = Man.new(@entrances_f[entrance_index].x, @entrances_f[entrance_index].y, @entrances_t[entrance_index].y)
  end

  def objects_list
    @front ? @objects_f : @objects_t
  end

  def toggle_view
    @angle = 0
    @toggling = 1
    @man.start_toggle
    objects_list.each(&:start_toggle)
  end

  def toggle_view_blocked(obstacle)
    @blocker = obstacle
    @timer = 0
  end

  def obstacles(depth = nil)
    @front ? @obstacles_f : @obstacles_t[depth]
  end

  def intersecting_tile_depths(x, y, w, h)
    i1 = x.floor / TILE_SIZE
    j1 = y.floor / TILE_SIZE
    i2 = (x + w).floor / TILE_SIZE
    j2 = (y + h).floor / TILE_SIZE
    (i1..i2).reduce([]) do |tiles, i|
      tiles.concat(@tiles_t[i][j1..j2].map { |cell| cell.map { |t| t[1] }.max })
    end
  end

  def find_z_by_depth(x, w, depth)
    i1 = x.floor / TILE_SIZE
    i2 = (x + w).floor / TILE_SIZE
    (i1..i2).each do |i|
      (0...TILE_Y_COUNT).each do |j|
        return (j + 0.5) * TILE_SIZE if @tiles_t[i][j].any? { |t| t[1] == depth }
      end
    end
    nil
  end

  def transition(&callback)
    @overlay_alpha = 0
    @transition_callback = callback
  end

  def update
    if @transition_callback
      @overlay_alpha += TRANSITION_RATE
      @overlay_alpha = 255 if @overlay_alpha > 255
      if @overlay_alpha == 255
        @transition_callback.call
        @transition_callback = nil
      end
      return
    elsif @toggling
      @angle += TOGGLE_RATE
      if @angle >= Math::PI / 2
        if @toggling == 1
          @front = !@front
          @toggling = 2
          @angle = 0
          @man.toggle_view(self)
          objects_list.each(&:start_toggle)
        else
          @toggling = nil
          @scale_y = 1
          @man.end_toggle(self)
          objects_list.each(&:end_toggle)
        end
      else
        @scale_y = Math.cos(@toggling == 1 ? @angle : Math::PI / 2 - @angle)
      end

      return
    elsif @blocker
      @timer += 1
      if @timer >= BLOCKER_T1 + BLOCKER_T2
        @blocker = nil
        toggle_view
      end

      return
    end

    if @overlay_alpha > 0
      @overlay_alpha -= TRANSITION_RATE
      return if @overlay_alpha >= 127
    end

    @man.update(self)
    ex_list = @front ? @exits_f : @exits_t
    if (ex = ex_list.find { |e| e.bounds.intersect?(@man.bounds) })
      transition { Game.go_to(ex.dest_scr, ex.dest_ent) }
      return
    end

    objects_list.each { |o| o.update(@man) }

    toggle_view if KB.key_pressed?(Gosu::KB_LEFT_SHIFT)
  end

  def draw
    offset_y = (SCREEN_HEIGHT * (1 - @scale_y)) / 2

    @bg.draw(0, offset_y, 0, 1, @scale_y)

    (0...TILE_X_COUNT).each do |i|
      (0...TILE_Y_COUNT).each do |j|
        if @front
          @tileset[@tiles_f[i][j]].draw(i * TILE_SIZE, offset_y + j * TILE_SIZE * @scale_y, 0, 1, @scale_y) if @tiles_f[i][j]
        else
          @tiles_t[i][j].each do |(index, depth)|
            dim = @max_depth == 0 ? 255 : 255 - (MAX_DIM_TINT * (@max_depth - depth).to_f / @max_depth).round
            color = 0xff000000 | (dim << 16) | (dim << 8) | dim
            @tileset[TOP_TILE_OFFSET + index].draw(i * TILE_SIZE, offset_y + j * TILE_SIZE * @scale_y, depth, 1, @scale_y, color)
          end
        end
      end
    end

    objects_list.each { |o| o.draw(offset_y, @scale_y) }
    @man.draw(offset_y, @scale_y)

    if @blocker
      a = @timer >= BLOCKER_T1 ? 1 - ((@timer - BLOCKER_T1).to_f / BLOCKER_T2) : @timer.to_f / BLOCKER_T1
      alpha = (204 * a).round
      G.window.draw_rect(@blocker.x, @blocker.y, @blocker.w, @blocker.h, (alpha << 24) | 0xff0000, 100)
    end

    if @overlay_alpha > 0
      G.window.draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, @overlay_alpha << 24, 1000)
    end
  end

  private

  def set_tile(matrix, tile, i, j)
    matrix[i][j] = tile
    i += 1
    if i == TILE_X_COUNT
      i = 0
      j += 1
    end
    [i, j]
  end

  def skip_tiles(i, j, count)
    prev_i = i
    i = (i + count) % TILE_X_COUNT
    j += count / TILE_X_COUNT
    j += 1 if i < prev_i
    [i, j]
  end
end
