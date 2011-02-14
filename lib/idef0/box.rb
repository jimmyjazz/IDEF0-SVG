require_relative 'point'
require_relative 'sides'

module IDEF0

  class Box

    extend Forwardable

    attr_reader :name
    attr_reader :top_side, :bottom_side, :left_side, :right_side

    def initialize(name)
      @name = name
      @top_left = Point::ORIGIN
      @top_side = TopSide.new(self)
      @bottom_side = BottomSide.new(self)
      @left_side = LeftSide.new(self)
      @right_side = RightSide.new(self)
    end

    def move_to(top_left)
      @top_left = top_left
    end

    def translate(dx, dy)
      move_to(@top_left.translate(dx, dy))
    end

    def x1
      @top_left.x
    end

    def y1
      @top_left.y
    end

    def x2
      x1 + width
    end

    def y2
      y1 + height
    end

    def right_edge
      x2
    end

    def bottom_edge
      y2
    end

    def sides
      [top_side, bottom_side, left_side, right_side]
    end

    def sort_anchors
      sides.each(&:sort_anchors)
    end

    def layout(lines)
      sides.each { |side| side.layout(lines) }
      translate(0, top_side.margin)
    end

    # TODO: Wrong level of abstraction

    def receives(name)
      left_side.expects(name)
    end

    def produces(name)
      right_side.expects(name)
    end

    def respects(name)
      top_side.expects(name)
    end

    def requires(name)
      bottom_side.expects(name)
    end

  end

end
