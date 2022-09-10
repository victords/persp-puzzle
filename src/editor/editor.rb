require 'minigl'
require_relative '../screen'
require_relative '../constants'

include MiniGL

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
      if count > 1
        tiles_t << "#{last_tiles[0].join(':')}*#{count}"
      else
        tiles_t << last_tiles.map { |t| t.join(':') }.join(',')
      end
    end

    while j < TILE_Y_COUNT
      tiles = @tiles_t[i][j]
      if tiles.count == 1 && tiles == last_tiles
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
end

class EditorWindow < GameWindow
  def initialize
    super(640, 720, false)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-4].join('/') + '/data'
    Res.retro_images = true

    @font = ImageFont.new(:font_normal, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"←→∞$ĞğİıÖöŞşÜüĈĉĜĝĤĥĴĵŜŝŬŭ",
                          [6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 6, 6, 6, 6, 4, 6, 6, 2, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 4, 6, 6, 8, 6, 6, 6,
                           6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 2, 3, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 8, 8,
                           10, 6, 6, 6, 2, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6], 11, 3)
    @txt_name = TextField.new(x: 10, y: 370, font: @font, img: :editor_textField, margin_x: 5, margin_y: 2)

    overwrite = false
    @buttons = [
      Button.new(x: 10, y: 395, font: @font, text: 'Load', img: :editor_button) do
        @screen = EditorScreen.new(@txt_name.text) unless @txt_name.text.empty?
      end,
      (@btn_save = Button.new(x: 10, y: 435, font: @font, text: 'Save', img: :editor_button) do
        path = "#{Res.prefix}screen/#{@txt_name.text}.txt"
        if overwrite
          save(path)
          overwrite = false
        elsif File.exist?(path)
          @btn_save.text = 'Overwrite?'
          overwrite = true
        else
          save(path)
        end
      end),
      Button.new(x: 10, y: 475, font: @font, text: 'Toggle', img: :editor_button) do
        @screen&.toggle_view
      end,
    ]
  end

  def save(path)
    File.open(path, 'w+') do |f|
      f.write(@screen.file_contents)
    end
    @btn_save.text = 'Save'
  end

  def update
    KB.update
    Mouse.update
    close if KB.key_pressed?(Gosu::KB_ESCAPE)

    @screen&.update if @screen&.toggling

    @txt_name.update
    @buttons.each(&:update)
  end

  def draw
    clear(0xffffff)

    @screen&.draw

    @txt_name.draw
    @buttons.each(&:draw)
  end
end

EditorWindow.new.show
