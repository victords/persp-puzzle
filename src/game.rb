require_relative 'screen'

include MiniGL

class Game
  class << self
    def init
      G.gravity = Vector.new(0, 0.5)

      @controller = Screen.new
    end

    def update
      KB.update
      @controller.update
    end

    def draw
      @controller.draw
    end
  end
end
