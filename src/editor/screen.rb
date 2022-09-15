require_relative '../screen'

include MiniGL

class EditorMan
  def draw(*args); end
end

class EditorScreen < Screen
  attr_reader :toggling

  def initialize(name, font)
    super(name)
    @man = EditorMan.new
    @ent_ex_icon = Res.imgs(:editor_inOut, 2, 1)
    @text_helper = TextHelper.new(font)
  end

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

    obstacles_f = @obstacles_f.map do |o|
      "#{[o.x, o.y, o.w, o.h].map { |v| v / TILE_SIZE }.join(',')}:#{o.depth}#{o.passable ? '!' : ''}"
    end
    entrances_f = @entrances_f.map { |e| "#{e.col},#{e.row}" }
    exits_f = @exits_f.map { |e| "#{e.col},#{e.row},#{e.dest_scr},#{e.dest_ent}" }
    objects_f = @objects_f.map { |o| "#{o.type_id},#{o.x / TILE_SIZE},#{o.y / TILE_SIZE}#{o.args ? ":#{o.args}" : ''}" }

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

    obstacles_t = @obstacles_t.map.with_index do |os, i|
      os.map { |o| "#{[o.x, o.y, o.w, o.h].map { |v| v / TILE_SIZE }.join(',')}:#{i}" }.join(';')
    end
    entrances_t = @entrances_t.map { |e| "#{e.col},#{e.row}" }
    exits_t = @exits_t.map { |e| "#{e.col},#{e.row},#{e.dest_scr},#{e.dest_ent}" }
    objects_t = @objects_t.map { |o| "#{o.type_id},#{o.x / TILE_SIZE},#{o.y / TILE_SIZE}#{o.args ? ":#{o.args}" : ''}" }

    [
      tiles_f.join(';'),
      obstacles_f.join(';'),
      entrances_f.join(';'),
      exits_f.join(';'),
      objects_f.join(';'),
      tiles_t.join(';'),
      obstacles_t.join(';'),
      entrances_t.join(';'),
      exits_t.join(';'),
      objects_t.join(';')
    ].join('|')
  end

  def toggle_immediate
    @front = !@front
  end

  def add_tile(i, j, tile, depth)
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

  def add_obstacle(i1, j1, i2, j2, passable, depth)
    x = i1 * TILE_SIZE
    y = j1 * TILE_SIZE
    w = (i2 - i1 + 1) * TILE_SIZE
    h = (j2 - j1 + 1) * TILE_SIZE
    if @front
      block = DepthBlock.new(x, y, w, h, passable, depth)
      @obstacles_f.delete_if { |o| o.bounds.intersect?(block.bounds) }
      @obstacles_f << block
    else
      @obstacles_t[depth] ||= []
      block = Block.new(x, y, w, h)
      @obstacles_t[depth].delete_if { |o| o.bounds.intersect?(block.bounds) }
      @obstacles_t[depth] << block
    end
  end

  def delete_obstacle(i, j, depth)
    x = i * TILE_SIZE
    y = j * TILE_SIZE
    list = @front ? @obstacles_f : @obstacles_t[depth]
    list.delete_if { |o| o.x <= x && o.x + o.w > x && o.y <= y && o.y + o.h > y && (o.is_a?(Block) || o.depth == depth) }
  end

  def add_entrance(i, j, index)
    list = delete_entrance(i, j)
    ent = Entrance.new(i, j, !@front)
    if index >= list.size
      list << ent
    else
      list.insert(index, ent)
    end
  end

  def delete_entrance(i, j)
    list = @front ? @entrances_f : @entrances_t
    list.delete_if { |e| e.col == i && e.row == j }
    list
  end

  def add_exit(i, j, dest_scr, dest_ent)
    list = delete_exit(i, j)
    list << Exit.new(i, j, dest_scr, dest_ent)
  end

  def delete_exit(i, j)
    list = @front ? @exits_f : @exits_t
    list.delete_if { |e| e.col == i && e.row == j }
    list
  end

  def add_object(i, j, type, args)
    list = delete_object(i, j)
    list << OBJECT_TYPES[type].new(i * TILE_SIZE, j * TILE_SIZE, args.empty? ? nil : args, @front)
  end

  def delete_object(i, j)
    list = @front ? @objects_f : @objects_t
    list.delete_if { |o| o.x / TILE_SIZE == i && o.y / TILE_SIZE == j }
    list
  end

  def draw(depth)
    super()

    (0...TILE_X_COUNT).each do |i|
      (0...TILE_Y_COUNT).each do |j|
        G.window.draw_outline(i * TILE_SIZE, j * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0x66000000, 100)
      end
    end

    obs_list = @front ? @obstacles_f.select { |o| o.depth == depth } : @obstacles_t[depth]
    obs_list&.each do |o|
      G.window.draw_quad(o.x, o.y, 0x80ff0000,
                         o.x + o.w, o.y, 0x8000ff00,
                         o.x, o.y + o.h, 0x800000ff,
                         o.x + o.w, o.y + o.h, 0x80cccccc, 100)
    end

    ent_list = @front ? @entrances_f : @entrances_t
    ent_list.each_with_index do |e, i|
      @ent_ex_icon[0].draw(e.col * TILE_SIZE, e.row * TILE_SIZE, 100)
      @text_helper.write_line(i.to_s, (e.col + 1) * TILE_SIZE - 3, e.row * TILE_SIZE + 8, :right, 0xffffff, 255, :border, 0, 1, 255, 100)
    end

    ex_list = @front ? @exits_f : @exits_t
    ex_list.each do |e|
      @ent_ex_icon[1].draw(e.col * TILE_SIZE, e.row * TILE_SIZE, 100)
      @text_helper.write_line("#{e.dest_scr}:#{e.dest_ent}", (e.col + 0.5) * TILE_SIZE, e.row * TILE_SIZE + 8, :center, 0xffffff, 255, :border, 0, 1, 255, 100)
    end
  end
end
