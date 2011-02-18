require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'
require_relative 'line'

module IDEF0

  class BackwardInputLine < Line

    def self.make_line(source, target)
      return unless source.after?(target)
      source.right_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.left_side.expects?(anchor.name)
      end
    end

    def attach
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.left_side.attach(self)
    end

    def sides_to_clear
      [@source.right_side, @source.bottom_side, @target.left_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        3
      when @source.bottom_side
        1
      when @target.left_side
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
      when @target.left_side
        [1]
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @target.left_side
        [-@source.sequence]
      else
        -super
      end
    end

    def x_vertical #the x position of this line's single vertical segment
      x1 + clearance_from(@source.right_side)
    end

    def y_horizontal
      @source.bottom_edge + clearance_from(@source.bottom_side)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x2+10, y_horizontal-5))
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
