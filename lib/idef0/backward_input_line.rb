require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'
require_relative 'line'

module IDEF0

  class BackwardInputLine < Line

    def self.make_line(source, target)
      return unless source.after?(target) || source == target
      source.right_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.left_side.expects?(anchor.name)
      end
    end

    def attach
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.left_side.attach(self)
      self
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

    def left_x_vertical #the x position of this line's left vertical segment
      x2 - clearance_from(@target.left_side)
    end

    def right_x_vertical #the x position of this line's right vertical segment
      x1 + clearance_from(@source.right_side)
    end

    def y_horizontal
      @source.bottom_edge + clearance_from(@source.bottom_side)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(left_x_vertical+10, y_horizontal-5))
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{right_x_vertical-10} #{y1} C #{right_x_vertical-5} #{y1} #{right_x_vertical} #{y1+5} #{right_x_vertical} #{y1+10} L #{right_x_vertical} #{y_horizontal-10} C #{right_x_vertical} #{y_horizontal-5} #{right_x_vertical-5} #{y_horizontal} #{right_x_vertical-10} #{y_horizontal} L #{left_x_vertical+10} #{y_horizontal} C #{left_x_vertical+5} #{y_horizontal} #{left_x_vertical} #{y_horizontal-5} #{left_x_vertical} #{y_horizontal-10} L #{left_x_vertical} #{y2+10} C #{left_x_vertical} #{y2+5} #{left_x_vertical+5} #{y2} #{left_x_vertical+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
