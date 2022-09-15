require 'minigl'
require_relative 'screen'
require_relative '../constants'

include MiniGL

class EditorWindow < GameWindow
  def initialize
    super(640, 800, false)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-4].join('/') + '/data'
    Res.retro_images = true

    @front = true
    @depth = 0
    @entrance_index = 0

    @font = ImageFont.new(:font_normal, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÁÉÍÓÚÀÃÕÂÊÔÑÇáéíóúàãõâêôñç0123456789.,:;!?¡¿/\\()[]+-%'\"←→∞$ĞğİıÖöŞşÜüĈĉĜĝĤĥĴĵŜŝŬŭ",
                          [6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 6, 6, 6, 6, 4, 6, 6, 2, 4, 5, 3, 8, 6, 6, 6, 6, 5, 6, 4, 6, 6, 8, 6, 6, 6,
                           6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                           6, 4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 3, 2, 3, 2, 6, 2, 6, 5, 5, 3, 3, 3, 3, 6, 4, 6, 2, 4, 8, 8,
                           10, 6, 6, 6, 2, 2, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6], 12, 3)
    @screen = EditorScreen.new(nil, @font)

    overwrite = false
    object_names = Screen::OBJECT_TYPES.map(&:name)
    @components = [
      (@txt_name = TextField.new(x: 10, y: 370, font: @font, img: :editor_textField, margin_x: 5, margin_y: 2)),
      Button.new(x: 10, y: 390, font: @font, text: 'Load', img: :editor_button) do
        unless @txt_name.text.empty?
          @screen = EditorScreen.new(@txt_name.text, @font)
          @front = true
        end
      end,
      (@btn_save = Button.new(x: 10, y: 425, font: @font, text: 'Save', img: :editor_button) do
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
      Button.new(x: 10, y: 465, font: @font, text: 'Toggle', img: :editor_button) do
        @screen.toggle_immediate
        @front = !@front
      end,
      Button.new(x: 10, y: 505, font: @font, text: 'Obstacle', img: :editor_button) do
        @cur_obj = [:obstacle]
      end,
      (@chk_passable =
        ToggleButton.new(x: 10, y: 540, font: @font, text: 'Passable', img: :editor_check,
                         center_x: false, center_y: false, margin_x: 25, margin_y: 2)
      ),
      Button.new(x: 10, y: 560, img: :editor_arrowUp) do
        @depth += 1
        @lbl_depth.text = "Depth: #{@depth}"
      end,
      Button.new(x: 10, y: 576, img: :editor_arrowDown) do
        if @depth > 0
          @depth -= 1
          @lbl_depth.text = "Depth: #{@depth}"
        end
      end,
      (@lbl_depth = Label.new(x: 48, y: 569, font: @font, text: "Depth: #{@depth}")),
      Button.new(x: 10, y: 600, font: @font, text: 'Entrance', img: :editor_button) do
        @cur_obj = [:entrance]
      end,
      Button.new(x: 10, y: 635, img: :editor_arrowUp) do
        @entrance_index += 1
        @lbl_index.text = "Index: #{@entrance_index}"
      end,
      Button.new(x: 10, y: 651, img: :editor_arrowDown) do
        if @entrance_index > 0
          @entrance_index -= 1
          @lbl_index.text = "Index: #{@entrance_index}"
        end
      end,
      (@lbl_index = Label.new(x: 48, y: 644, font: @font, text: "Index: #{@entrance_index}")),
      Button.new(x: 10, y: 675, font: @font, text: 'Exit', img: :editor_button) do
        @cur_obj = [:exit]
      end,
      Label.new(x: 10, y: 710, font: @font, text: 'Destination'),
      (@txt_dest_scr = TextField.new(x: 10, y: 725, font: @font, img: :editor_textFieldShort, margin_x: 5, margin_y: 2)),
      (@txt_dest_ent = TextField.new(x: 63, y: 725, font: @font, img: :editor_textFieldShort, margin_x: 5, margin_y: 2)),
      DropDownList.new(x: 330, y: 370, font: @font, img: :editor_dropDown, opt_img: :editor_ddButton, text_margin: 5,
                       options: [''].concat(object_names)) do |old_value, new_value|
        @cur_obj = new_value.empty? ? nil : [:object, object_names.index(new_value)]
        @txt_args.text = '' if old_value != new_value
      end,
      (@txt_args = TextField.new(x: 330, y: 390, font: @font, img: :editor_textField, margin_x: 5, margin_y: 2))
    ]

    tileset = Gosu::Image.new("#{Res.prefix}tileset/1.png")
    @tileset = [
      tileset.subimage(0, 0, 200, 100),
      tileset.subimage(0, 100, 200, 100),
    ]
    (0..9).each do |i|
      (0..4).each do |j|
        @components << (Button.new(x: 120 + i * TILE_SIZE, y: 370 + j * TILE_SIZE, width: TILE_SIZE, height: TILE_SIZE) do
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

    @components.each do |c|
      c.update if c.respond_to?(:update)
    end

    return unless Mouse.over?(0, 0, 640, 360)

    i = Mouse.x / TILE_SIZE
    j = Mouse.y / TILE_SIZE
    if Mouse.button_down?(:left)
      pressed = Mouse.button_pressed?(:left)
      case cur_obj_type
      when :tile
        @screen.add_tile(i, j, @cur_obj[1], @depth)
      when :obstacle
        if pressed
          # origin, min, max
          @area = [i, j, i, j, i, j]
        else
          update_area(i, j)
        end
      when :entrance
        @screen.add_entrance(i, j, @entrance_index) if pressed
      when :exit
        if pressed && !@txt_dest_scr.text.empty? && !@txt_dest_ent.text.empty?
          @screen.add_exit(i, j, @txt_dest_scr.text.to_i, @txt_dest_ent.text.to_i)
        end
      when :object
        @screen.add_object(i, j, @cur_obj[1], @txt_args.text) if pressed
      end
    elsif Mouse.button_released?(:left)
      if cur_obj_type == :obstacle
        @screen.add_obstacle(*@area[2..], @chk_passable.checked, @depth) if @area
      end
      @area = nil
    end

    if Mouse.button_down?(:right)
      case cur_obj_type
      when :tile
        @screen.delete_tile(i, j)
      when :obstacle
        @screen.delete_obstacle(i, j, @depth)
      when :entrance
        @screen.delete_entrance(i, j)
      when :exit
        @screen.delete_exit(i, j)
      when :object
        @screen.delete_object(i, j)
      end
    end
  end

  def draw_outline(x, y, width, height, color, z_index)
    draw_line(x, y, color, x + width, y, color, z_index)
    draw_line(x, y + height - 1, color, x + width, y + height - 1, color, z_index)
    draw_line(x + 1, y + 1, color, x + 1, y + height - 1, color, z_index)
    draw_line(x + width, y + 1, color, x + width, y + height - 1, color, z_index)
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

    @components.each(&:draw)

    @tileset[@front ? 0 : 1].draw(120, 370, 0)
    if cur_obj_type == :tile
      i = @cur_obj[1] % 10
      j = @cur_obj[1] / 10
      G.window.draw_rect(120 + i * TILE_SIZE, 370 + j * TILE_SIZE, TILE_SIZE, TILE_SIZE, 0x80ffff00, 0)
    end
  end
end

EditorWindow.new.show
