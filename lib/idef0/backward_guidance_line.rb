require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'
require_relative 'internal_guidance_line'

module IDEF0

  class BackwardGuidanceLine < InternalGuidanceLine

    def self.make_line(source, target)
      return unless source.after?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.top_side.expects?(name)
      end
    end

    def top_edge
      y_horizontal
    end

    def right_edge
      x_vertical
    end

    def sides_to_clear
      [@target.top_side, @source.right_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        1
      when @target.top_side
        3
      else
        super
      end
    end

    def clearance_precedence(side)
      case side
      when @source.right_side
        [1, -@target.sequence, source_anchor.sequence]
      when @target.top_side
        [1, @source.sequence, -target_anchor.sequence]
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @target.top_side
        -super
      else
        super
      end
    end

    def x_vertical
      x1 + clearance_from(@source.right_side)
    end

    def y_horizontal
      y2 - clearance_from(@target.top_side)
    end

    def label
      RightAlignedLabel.new(@name, Point.new(right_edge-10, y_horizontal-5+20))
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1-5} #{x_vertical} #{y1-10} L #{x_vertical} #{y_horizontal+10} C #{x_vertical} #{y_horizontal+5} #{x_vertical-5} #{y_horizontal} #{x_vertical-10} #{y_horizontal} L #{x2+10} #{y_horizontal} C #{x2+5} #{y_horizontal} #{x2} #{y_horizontal+5} #{x2} #{y_horizontal+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
