require_relative 'collection_negation'
require_relative 'internal_guidance_line'

module IDEF0

  class ForwardGuidanceLine < InternalGuidanceLine

    def self.make_line(source, target)
      return unless source.before?(target)
      source.right_side.each_anchor do |anchor|
        yield(new(source, target, anchor.name)) if target.top_side.expects?(anchor.name)
      end
    end

    def clearance_group(side)
      case side
      when @source.right_side
        2
      when @target.top_side
        1
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @target.top_side
        [-@source.sequence]
      when @source.right_side
        [-@target.sequence]
      else
        super
      end
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x2-10} #{y1} C #{x2-5} #{y1} #{x2} #{y1+5} #{x2} #{y1+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
