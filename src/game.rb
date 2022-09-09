require_relative 'screen'

include MiniGL

class Game
  class << self
    attr_reader :font_nisled

    def init
      G.gravity = Vector.new(0, 0.5)

      # @font_normal = ImageFont.new(:font_normal, '', [], 11, 3)
      @font_nisled = ImageFont.new(:font_nisled,
                                   'abkdãefghéijlmnoprsóutvxz',
                                   [15, 9, 15, 12, 15,
                                    12, 12, 15, 12, 12,
                                    9, 9, 15, 12, 12,
                                    12, 9, 12, 12, 12,
                                    12, 9, 12, 12, 15],
                                   18, 9)
      @controller = Screen.new('1')
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
