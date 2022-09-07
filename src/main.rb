require 'minigl'

include MiniGL

class Window < GameWindow
  def initialize
    super(800, 600, false)
  end

  def draw
    clear(0xffffff)

  end
end

Window.new.show
