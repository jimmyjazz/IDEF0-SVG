module IDEF0
  class BoundsExtension
    attr_reader :north, :south, :east, :west

    def initialize
      @north = @south = @east = @west = 0
    end

    def north=(value)
      @north = value if value > @north
    end

    def south=(value)
      @south = value if value > @south
    end

    def east=(value)
      @east = value if value > @east
    end

    def west=(value)
      @west = value if value > @west
    end
  end
end
