require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'
require_relative 'internal_mechanism_line'

module IDEF0

  class BackwardMechanismLine < InternalMechanismLine

    def self.make_line(source, target)
      return unless source.after?(target) || source == target
      source.right_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.bottom_side.expects?(anchor.name)
      end
    end

    def y_horizontal
      @source.bottom_edge + clearance_from(@source.bottom_side)
    end

    def right_edge
      x_vertical
    end

    def sides_to_clear
      [@source.right_side, @source.bottom_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        3
      when @target.bottom_side
        3
      when @source.bottom_side
        1
      else
        super
      end
    end

    def clearance_precedence(side)
      case side
      when @source.right_side
        [-@target.sequence, -target_anchor.sequence]
      when @source.bottom_side
        [-@target.sequence, 2, -target_anchor.sequence]
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @target.bottom_side
        [-@source.sequence]
      else
        super
      end
    end

    def label
      RightAlignedLabel.new(@name, Point.new(right_edge-10, y_horizontal-5))
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1+5} #{x_vertical} #{y1+10} L #{x_vertical} #{y_horizontal-10} C #{x_vertical} #{y_horizontal-5} #{x_vertical-5} #{y_horizontal} #{x_vertical-10} #{y_horizontal} L #{x2+10} #{y_horizontal} C #{x2+5} #{y_horizontal} #{x2} #{y_horizontal-5} #{x2} #{y_horizontal-10} L #{x2} #{y2}' />
#{svg_up_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
