require 'minigl'
require_relative 'constants'
require_relative 'game'

include MiniGL

class Window < GameWindow
  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, true)
    Res.prefix = File.expand_path(__FILE__).split('/')[..-3].join('/') + '/data'
    Res.retro_images = true
    Game.init
  end

  def update
    close if KB.key_pressed?(Gosu::KB_ESCAPE)
    Game.update
  end

  def draw
    Game.draw
  end
end

Window.new.show
