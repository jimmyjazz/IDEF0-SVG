require_relative 'array_set'
require_relative 'positive_number_detection'
require_relative 'point'
require_relative 'box'
require_relative 'process_box'
require_relative 'lines'

module IDEF0

  def self.diagram(name, &block)
    Diagram.new(name).tap do |diagram|
      diagram.instance_eval(&block)
      diagram.sequence_boxes
      diagram.create_lines
      diagram.connect_lines
      diagram.sequence_anchors
      diagram.layout
    end
  end

  class Diagram < Box

    attr_reader :width, :height

    def initialize(name)
      super
      @boxes = ArraySet.new
      @lines = ArraySet.new
      @width = @height = 0
    end

    def resize(width, height)
      @width = width
      @height = height
    end

    def box(name, &block)
      @boxes.get(lambda { |p| p.name == name }) { ProcessBox.new(name) }.instance_eval(&block)
    end

    def bottom_edge
      (@boxes + @lines).map(&:bottom_edge).max || 0
    end

    def right_edge
      (@boxes + @lines).map(&:right_edge).max || 0
    end

    def sequence_boxes
      @boxes = @boxes.sequence_by(&:precedence)
    end

    def create_lines
      @boxes.each do |box|
        box.left_side.each do |input|
          @lines << ExternalInputLine.new(self, box, input) if left_side.expects?(input)
        end

        box.top_side.each do |guidance|
          @lines << ExternalGuidanceLine.new(self, box, guidance) if top_side.expects?(guidance)
        end

        box.bottom_side.each do |mechanism|
          @lines << ExternalMechanismLine.new(self, box, mechanism) if bottom_side.expects?(mechanism)
        end

        box.right_side.each do |output|
          @lines << ExternalOutputLine.new(box, self, output) if right_side.expects?(output)

          @boxes.each do |target|
            next unless target.after?(box)
            @lines << ForwardInputLine.new(box, target, output) if target.left_side.expects?(output)
            @lines << ForwardGuidanceLine.new(box, target, output) if target.top_side.expects?(output)
            @lines << ForwardMechanismLine.new(box, target, output) if target.bottom_side.expects?(output)
          end

          @boxes.each do |target|
            next unless target.before?(box)
            @lines << BackwardInputLine.new(box, target, output) if target.left_side.expects?(output)
            @lines << BackwardGuidanceLine.new(box, target, output) if target.top_side.expects?(output)
            @lines << BackwardMechanismLine.new(box, target, output) if target.bottom_side.expects?(output)
          end
        end
      end
    end

    def connect_lines
      @lines.each(&:connect)
    end

    def sequence_anchors
      @boxes.each(&:sequence_anchors)
    end

    def layout
      @boxes.inject(@top_left) do |point, box|
        box.move_to(point)
        box.layout(@lines)
        Point.new(box.x2 + box.right_side.margin, box.y2 + box.bottom_side.margin)
      end

      @lines.each { |line| line.avoid(@lines.delete(line)) }

      dx, dy = [@lines.map(&:left_edge), @lines.map(&:top_edge)].map do |set|
        set.reject(&:positive?).map(&:abs).max || 0
      end

      @boxes.each { |box| box.translate(dx, dy) }

      resize(right_edge, bottom_edge)
    end

    def to_svg
      <<-XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"
"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [
<!ATTLIST svg xmlns:xlink CDATA #FIXED "http://www.w3.org/1999/xlink">
]>
<svg xmlns='http://www.w3.org/2000/svg'
xmlns:xlink='http://www.w3.org/1999/xlink'
width='#{width}pt' height='#{height}pt'
viewBox='#{x1.to_f} #{y1.to_f} #{x2.to_f} #{y2.to_f}'
>
<style type='text/css'>
  text {
    font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
    font-size: 12px;
  }
</style>
<g>
  #{generate_boxes}
  #{generate_lines}
</g>
</svg>
XML
    end

    def generate_boxes
      @boxes.map(&:to_svg).join("\n")
    end

    def generate_lines
      @lines.map(&:to_svg).join("\n")
    end

  end

end
