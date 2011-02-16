require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0

  class ExternalInputLine < ExternalLine

    def self.make_line(source, target)
      source.left_side.each do |name|
        yield(new(source, target, name)) if target.left_side.expects?(name)
      end
    end

    def initialize(*args)
      super
      clear(@target.left_side, 20)
    end

    def connect
      @target_anchor = target.left_side.attach(self)
    end

    def x1
      x2 - clearance_from(@target.left_side)
    end

    def y1
      target_anchor.y
    end

    def y2
      y1
    end

    def bounding_box(p1, p2)
      clear(@target.left_side, x1-p1.x+clearance_from(@target.left_side))
    end

    def avoid(lines)
      clear(@target.left_side, [minimum_length, clearance_from(@target.left_side)].max)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x1+5, y1-5))
    end

    def clearance_group(side)
      case
      when @target.left_side
        2
      else
        super
      end
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
