require_relative 'constants'

include MiniGL

class Screen
  def initialize
    @bg = Res.img(:bg_1)

    @tileset = Res.tileset('1', 20, 20)
    @tiles_f = Array.new(32) { Array.new(18) }
    @tiles_t = Array.new(32) { Array.new(18) }
    File.open("#{Res.prefix}screen/1.txt") do |f|
      front, top = f.read.split('|').map { |s| s.split(';') }

      i = 0; j = 0
      front.each do |d|
        if d[0] == '_'
          n = d[1..].to_i
          prev_i = i
          i = (i + n) % TILE_X_COUNT
          j += n / TILE_X_COUNT
          j += 1 if i < prev_i
        elsif d.index('*')
          tile = d.to_i
          count = d.split('*')[1].to_i
          count.times { i, j = set_tile(@tiles_f, tile, i, j) }
        else
          i, j = set_tile(@tiles_f, d.to_i, i, j)
        end
      end

      i = 0; j = 0
      @max_depth = 0
      top.each do |d|
        if d.index('*')
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
    end

    @front = true
    @y_scale = 1
  end

  def toggle_view
    @angle = 0
    @toggling = 1
  end

  def update
    if @toggling
      @angle += Math::PI / 60
      if @angle >= Math::PI / 2
        if @toggling == 1
          @front = !@front
          @toggling = 2
          @angle = 0
        else
          @toggling = nil
          @y_scale = 1
        end
      else
        @y_scale = Math.cos(@toggling == 1 ? @angle : Math::PI / 2 - @angle)
      end

      return
    end

    toggle_view if KB.key_pressed?(Gosu::KB_SPACE)
  end

  def draw
    offset_y = (SCREEN_HEIGHT * (1 - @y_scale)) / 2

    @bg.draw(0, offset_y, 0, 1, @y_scale)

    (0...TILE_X_COUNT).each do |i|
      (0...TILE_Y_COUNT).each do |j|
        if @front
          @tileset[@tiles_f[i][j]].draw(i * TILE_SIZE, offset_y + j * TILE_SIZE * @y_scale, 0, 1, @y_scale) if @tiles_f[i][j]
        else
          @tiles_t[i][j]&.each do |tile_info|
            dim = 255 - (MAX_DIM_TINT * (@max_depth - tile_info[1]).to_f / @max_depth).round
            color = 0xff000000 | (dim << 16) | (dim << 8) | dim
            @tileset[TOP_TILE_OFFSET + tile_info[0]].draw(i * TILE_SIZE, offset_y + j * TILE_SIZE * @y_scale, 0, 1, @y_scale, color)
          end
        end
      end
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
end
