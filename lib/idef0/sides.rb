require_relative 'array_set'
require_relative 'point'
require_relative 'anchor'

module IDEF0
  class Side
    attr_reader :margin

    def initialize(box)
      @box = box
      @anchors = ArraySet.new
      @margin = 0
    end

    def name
      "#{@box.name}.#{self.class.name}"
    end

    # TODO: This is a fudge to make stuff work
    def each_anchor(&block)
      @anchors.each(&block)
    end

    def each_unattached_anchor(&block)
      @anchors.reject(&:attached?).each(&block)
    end

    def expects(name)
      @anchors.get(lambda { |a| a.name == name }) { Anchor.new(self, name) }
    end

    def expects?(name)
      @anchors.any? { |a| a.name == name }
    end

    def attach(line)
      expects(line.name).tap { |anchor| anchor.attach(line) }
    end

    def sequence_anchors
      @anchors = @anchors.sort_by(&:precedence).sequence!
    end

    def anchor_count
      @anchors.count
    end

    def x1
      @box.x1
    end

    def x2
      @box.x2
    end

    def y1
      @box.y1
    end

    def y2
      @box.y2
    end

    def width
      x2 - x1
    end

    def height
      y2 - y1
    end

    def layout(lines)
      clearance_groups = lines.select { |line| line.clear?(self) }
        .group_by { |line| line.clearance_group(self) }
        .values

      clearance_groups.each do |lines|
        lines.sort_by { |line| line.clearance_precedence(self) }
          .each_with_index { |line, index| line.clear(self, 20 + index * 20) }
      end

      line_count = clearance_groups.map(&:count).max || 0

      @margin = 20 + line_count * 20
    end

  end

  class HorizontalSide < Side
    def y
      y1
    end

    def anchor_point(n)
      baseline = x1+width/2 - 20*(@anchors.count - 1)/2
      x = baseline + n * 20
      Point.new(x, y)
    end
  end

  class VerticalSide < Side
    def x
      x1
    end

    def anchor_point(n)
      baseline = y1+height/2 - 20*(@anchors.count - 1)/2
      y = baseline + n * 20
      Point.new(x, y)
    end
  end

  class TopSide < HorizontalSide
    def y2
      @box.y1
    end
  end

  class BottomSide < HorizontalSide
    def y1
      @box.y2
    end
  end

  class LeftSide < VerticalSide
    def x2
      @box.x1
    end
  end

  class RightSide < VerticalSide
    def x1
      @box.x2
    end
  end
end
