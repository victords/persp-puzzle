require 'minigl'
require_relative 'screen'
require_relative '../constants'

include MiniGL

class EditorWindow < GameWindow
  def initialize
    super(640, 720, false)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-4].join('/') + '/data'
    Res.retro_images = true

    @screen = EditorScreen.new(nil)
    @front = true
    @depth = 0

    @font = ImageFont.new(:font_normal, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"←→∞$ĞğİıÖöŞşÜüĈĉĜĝĤĥĴĵŜŝŬŭ",
                          [6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 6, 6, 6, 6, 4, 6, 6, 2, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 4, 6, 6, 8, 6, 6, 6,
                           6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 2, 3, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 8, 8,
                           10, 6, 6, 6, 2, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6], 12, 3)

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
      Button.new(x: 10, y: 515, font: @font, text: 'Obstacle', img: :editor_button) do
        @cur_obj = [:obstacle]
      end,
      Button.new(x: 10, y: 555, img: :editor_arrowUp) do
        @depth += 1
        @labels[0].text = "Depth: #{@depth}"
      end,
      Button.new(x: 10, y: 571, img: :editor_arrowDown) do
        if @depth > 0
          @depth -= 1
          @labels[0].text = "Depth: #{@depth}"
        end
      end,
    ]

    @labels = [
      Label.new(x: 48, y: 564, font: @font, text: "Depth: #{@depth}"),
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
  end

  def save(path)
    File.open(path, 'w+') do |f|
      f.write(@screen.file_contents)
    end
    @btn_save.text = 'Save'
  end

  def cur_obj_type
    @cur_obj && @cur_obj[0]
  end

  def update_area(i, j)
    return unless @area

    @area[2..] = [
      [@area[0], i].min,
      [@area[1], j].min,
      [@area[0], i].max,
      [@area[1], j].max,
    ]
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
      case cur_obj_type
      when :tile
        @screen.change_tile(i, j, @cur_obj[1], @depth)
      when :obstacle
        if Mouse.button_pressed?(:left)
          # origin, min, max
          @area = [i, j, i, j, i, j]
        else
          update_area(i, j)
        end
      end
    elsif Mouse.button_released?(:left)
      if cur_obj_type == :obstacle
        @screen.add_obstacle(*@area[2..], @depth) if @area
      end
      @area = nil
    end

    if Mouse.button_down?(:right)
      case cur_obj_type
      when :tile
        @screen.delete_tile(i, j)
      when :obstacle
        @screen.delete_obstacle(i, j, @depth)
      end
    end
  end

  def draw
    clear(0xffffff)

    @screen.draw(@depth)
    if @area
      G.window.draw_rect(@area[2] * TILE_SIZE,
                         @area[3] * TILE_SIZE,
                         (@area[4] - @area[2] + 1) * TILE_SIZE,
                         (@area[5] - @area[3] + 1) * TILE_SIZE,
                         0x80ffff00, 100)
    end

    @txt_name.draw
    @buttons.each(&:draw)
    @labels.each(&:draw)

    @tileset[@front ? 0 : 1].draw(120, 370, 0)
    if cur_obj_type == :tile
      i = @cur_obj[1] % 10
      j = @cur_obj[1] / 10
      G.window.draw_rect(120 + i * TILE_SIZE, 370 + j * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0x80ffff00, 0)
    end
  end
end

EditorWindow.new.show
