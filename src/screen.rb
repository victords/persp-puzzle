require_relative 'constants'

include MiniGL

class Screen
  def initialize
    @tileset = Res.tileset('1', 20, 20)
    @tiles = Array.new(32) { Array.new(18) }
    File.open("#{Res.prefix}screen/1.txt") do |f|
      i = 0; j = 0
      f.read.split(';').each do |d|
        if d[0] == '_'
          n = d[1..].to_i
          prev_i = i
          i = (i + n) % TILE_X_COUNT
          j += n / TILE_X_COUNT
          j += 1 if i < prev_i
        elsif (ind = d.index('*'))
          tile = d.to_i
          count = d[(ind + 1)..].to_i
          count.times { i, j = set_tile(tile, i, j) }
        else
          i, j = set_tile(d.to_i, i, j)
        end
      end
    end
  end

  def update

  end

  def draw
    (0...TILE_X_COUNT).each do |i|
      (0...TILE_Y_COUNT).each do |j|
        @tileset[@tiles[i][j]].draw(i * TILE_SIZE, j * TILE_SIZE, 0) if @tiles[i][j]
      end
    end
  end

  private

  def set_tile(tile, i, j)
    @tiles[i][j] = tile
    i += 1
    if i == TILE_X_COUNT
      i = 0
      j += 1
    end
    [i, j]
  end
end
