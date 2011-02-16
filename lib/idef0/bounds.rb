module IDEF0

  class Bounds

    attr_reader :x1, :y1, :x2, :y2

    def initialize(x1, y1, x2, y2)
      @x1, @y1, @x2, @y2 = x1, y1, x2, y2
    end

  end

end
