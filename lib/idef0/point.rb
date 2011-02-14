module IDEF0

  class Point

    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def translate(dx, dy)
      self.class.new(@x + dx, @y + dy)
    end

    ORIGIN = new(0, 0)

  end

end
