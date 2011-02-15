require_relative 'point'
require_relative 'labels'
require_relative 'external_line'

module IDEF0

  class ExternalOutputLine < ExternalLine

    def self.make_line(target, source)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.right_side.expects?(name)
      end
    end

    def connect
      @source_anchor = source.right_side.attach(self)
    end

    def x2
      [x1 + minimum_length, target.x2].max
    end

    def y2
      y1
    end

    def label
      RightAlignedLabel.new(@name, Point.new(target.x2-5, y2-5))
    end

    def clearance_group(side)
      case
      when @source.right_side
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
