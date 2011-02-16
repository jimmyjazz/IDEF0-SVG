require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0

  class ExternalGuidanceLine < ExternalLine

    def self.make_line(source, target)
      source.top_side.each do |name|
        yield(new(source, target, name)) if target.top_side.expects?(name)
      end
    end

    def initialize(*args)
      super
      clear(@target.top_side, 20)
    end

    def connect
      @target_anchor = target.top_side.attach(self)
    end

    def bounding_box(p1, p2)
      clear(@target.top_side, y1-p1.y+40+clearance_from(@target.top_side))
    end

    def avoid(lines)
      while lines.any?{ |other| label.overlapping?(other.label) } do
        clear(@target.top_side, 20+clearance_from(@target.top_side))
      end
    end

    def x1
      target_anchor.x
    end

    def y1
      y2 - clearance_from(@target.top_side)
    end

    def x2
      x1
    end

    def label
      CentredLabel.new(@name, Point.new(x1, y1+20-5))
    end

    def clearance_group(side)
      case
      when @target.top_side
        2
      else
        super
      end
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1+20}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
