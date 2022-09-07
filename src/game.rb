require_relative 'screen'

class Game
  class << self
    def init
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
