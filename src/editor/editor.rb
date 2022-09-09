require 'minigl'

include MiniGL

class EditorWindow < GameWindow
  def initialize
    super(1280, 720, false)
    Res.prefix = File.expand_path(__FILE__).split('/')[0..-4].join('/') + '/data'
    Res.retro_images = true
  end

  def draw
    clear(0xffffff)
  end
end

EditorWindow.new.show
