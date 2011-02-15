require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'
require_relative 'internal_mechanism_line'

module IDEF0

  class ForwardMechanismLine < InternalMechanismLine

    def self.make_line(source, target)
      return unless source.before?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.bottom_side.expects?(name)
      end
    end

    def y_horizontal
      y2 + clearance_from(@target.bottom_side)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x_vertical+10, y_horizontal-5))
    end

    def sides_to_clear
      [@source.right_side, @target.bottom_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        3
      when @target.bottom_side
        1
      else
        super
      end
    end

    def clearance_precedence(side)
      case side
      when @source.right_side
        [2, -@target.sequence, 1, -target_anchor.sequence]
      when @target.bottom_side
        [-@source.sequence, 1, target_anchor.sequence]
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @source.right_side
        -super
      else
        super
      end
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1+5} #{x_vertical} #{y1+10} L #{x_vertical} #{y_horizontal-10} C #{x_vertical} #{y_horizontal-5} #{x_vertical+5} #{y_horizontal} #{x_vertical+10} #{y_horizontal}  L #{x2-10} #{y_horizontal} C #{x2-5} #{y_horizontal} #{x2} #{y_horizontal-5} #{x2} #{y_horizontal-10} L #{x2} #{y2}' />
#{svg_up_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
