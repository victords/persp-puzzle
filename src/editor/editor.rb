require 'minigl'
require_relative 'screen'
require_relative '../constants'

include MiniGL

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
        unless @txt_name.text.empty?
          @screen = EditorScreen.new(@txt_name.text)
          @front = true
        end
      end,
      (@btn_save = Button.new(x: 10, y: 435, font: @font, text: 'Save', img: :editor_button) do
        next if @txt_name.text.empty?
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
        @screen.toggle_view
        @front = !@front
      end,
      Button.new(x: 10, y: 515, img: :editor_arrowUp) do
        @depth += 1
      end,
      Button.new(x: 10, y: 531, img: :editor_arrowDown) do
        @depth -= 1 if @depth > 0
      end
    ]

    tileset = Gosu::Image.new("#{Res.prefix}tileset/1.png")
    @tileset = [
      tileset.subimage(0, 0, 200, 100),
      tileset.subimage(0, 100, 200, 100),
    ]
    (0..9).each do |i|
      (0..4).each do |j|
        @buttons << (Button.new(x: 120 + i * TILE_SIZE, y: 370 + j * TILE_SIZE, width: TILE_SIZE, height: TILE_SIZE) do
          @cur_obj = [:tile, 10 * j + i]
        end)
      end
    end

    @screen = EditorScreen.new(nil)
    @front = true
    @depth = 0
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

    @screen.update if @screen.toggling

    @txt_name.update
    @buttons.each(&:update)

    return unless Mouse.over?(0, 0, 640, 360)

    i = Mouse.x / TILE_SIZE
    j = Mouse.y / TILE_SIZE
    if Mouse.button_down?(:left)
      case @cur_obj&.[](0)
      when :tile
        @screen.change_tile(i, j, @cur_obj[1], @depth)
      end
    elsif Mouse.button_down?(:right)
      @screen.delete_tile(i, j)
    end
  end

  def draw
    clear(0xffffff)

    @screen.draw

    @txt_name.draw
    @buttons.each(&:draw)
    @font.draw_text("Depth: #{@depth}", 48, 525, 0, 1, 1, 0xff000000)

    @tileset[@front ? 0 : 1].draw(120, 370, 0)
    if @cur_obj
      if @cur_obj[0] == :tile
        i = @cur_obj[1] % 10
        j = @cur_obj[1] / 10
        G.window.draw_rect(120 + i * TILE_SIZE, 370 + j * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0x80ffff00, 0)
      end
    end
  end
end

EditorWindow.new.show
