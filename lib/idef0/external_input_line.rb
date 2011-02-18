require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0

  class ExternalInputLine < ExternalLine

    def self.make_line(source, target)
      source.left_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.left_side.expects?(anchor.name)
      end
    end

    def initialize(*args)
      super
      clear(@target.left_side, 20)
    end

    def attach
      @target_anchor = target.left_side.attach(self)
      self
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

    def bounds(bounds)
      add_clearance_from(@target.left_side, x1 - bounds.x1 + 40)
    end

    def avoid(lines, bounds_extension)
      bounds_extension.west = minimum_length
    end

    def extend_bounds(extension)
      add_clearance_from(@target.left_side, extension.west)
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
#{svg_line(x1, y1, x2, y2)}
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
