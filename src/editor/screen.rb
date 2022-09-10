require_relative '../screen'

class EditorScreen < Screen
  attr_reader :toggling

  def file_contents
    i = j = 0
    forward = lambda do
      i += 1
      if i == TILE_X_COUNT
        i = 0
        j += 1
      end
    end

    count = 0
    last_tile = -1
    tiles_f = []
    add_f_tile = lambda do
      if last_tile
        tiles_f << (count > 1 ? "#{last_tile}*#{count}" : last_tile.to_s)
      else
        tiles_f << "_#{count}"
      end
    end

    while j < TILE_Y_COUNT
      tile = @tiles_f[i][j]
      if tile == last_tile
        count += 1
      else
        add_f_tile.call if last_tile != -1
        last_tile = tile
        count = 1
      end
      forward.call
    end
    add_f_tile.call

    i = j = count = 0
    last_tiles = nil
    tiles_t = []
    add_t_tile = lambda do
      if last_tiles.empty?
        tiles_t << "_#{count}"
      elsif count > 1
        tiles_t << "#{last_tiles[0].join(':')}*#{count}"
      else
        tiles_t << last_tiles.map { |t| t.join(':') }.join(',')
      end
    end

    while j < TILE_Y_COUNT
      tiles = @tiles_t[i][j]
      if tiles.count <= 1 && tiles == last_tiles
        count += 1
      else
        add_t_tile.call if last_tiles
        last_tiles = tiles
        count = 1
      end
      forward.call
    end
    add_t_tile.call

    [
      tiles_f.join(';'),
      @obstacles_f.map { |o| "#{[o.x, o.y, o.w, o.h].map { |v| v / TILE_SIZE }.join(',')}:#{o.depth}" }.join(';'),
      tiles_t.join(';'),
      @obstacles_t.map.with_index { |os, i| os.map { |o| "#{[o.x, o.y, o.w, o.h].map { |v| v / TILE_SIZE }.join(',')}:#{i}" }.join(';') }.join(';')
    ].join('|')
  end

  def toggle_rate
    Math::PI / 2
  end

  def change_tile(i, j, tile, depth)
    if @front
      @tiles_f[i][j] = tile
    else
      @tiles_t[i][j].delete_if { |t| t[1] == depth }
      @tiles_t[i][j] << [tile, depth]
      @max_depth = depth if depth > @max_depth
    end
  end

  def delete_tile(i, j)
    if @front
      @tiles_f[i][j] = nil
    else
      @tiles_t[i][j] = []
      @max_depth = @tiles_t.flatten.select.with_index { |_, i| i.odd? }.max
    end
  end
end
