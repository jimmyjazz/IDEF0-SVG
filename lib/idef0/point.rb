module IDEF0
  class Point
    attr_reader :x, :y

    def self.origin
      @origin ||= new(0, 0)
    end

    def initialize(x, y)
      @x = x
      @y = y
    end

    def translate(dx, dy)
      self.class.new(@x + dx, @y + dy)
    end
  end
end
