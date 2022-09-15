include MiniGL

class Base < GameObject
  attr_reader :type_id, :args

  def initialize(type_id, args, x, y, w, h, img, img_gap = nil, sprite_cols = nil, sprite_rows = nil)
    super(x, y, w, h, img, img_gap, sprite_cols, sprite_rows)
    @type_id = type_id
    @args = args
  end

  def start_toggle
    @toggling = true
  end

  def end_toggle
    @toggling = false
  end

  def draw(offset_y, scale_y)
    phys_y = @y
    @y = offset_y + scale_y * @y
    super(nil, 1, scale_y)
    @y = phys_y
  end
end
