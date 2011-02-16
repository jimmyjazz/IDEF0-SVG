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
      diagram.create_lines
      diagram.attach_lines
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

    def top_edge
      (@boxes + @lines).map(&:top_edge).min || 0
    end

    def bottom_edge
      (@boxes + @lines).map(&:bottom_edge).max || 0
    end

    def left_edge
      (@boxes + @lines).map(&:left_edge).min || 0
    end

    def right_edge
      (@boxes + @lines).map(&:right_edge).max || 0
    end

    def create_lines
      backward_count = nil

      @boxes.sort_by(&:precedence).permutation do |boxes|
        boxes = boxes.sequence!
        lines = @boxes.reduce(ArraySet.new) do |lines, target|
          EXTERNAL_LINE_TYPES.each do |line_type|
            line_type.make_line(self, target) { |line| lines.add(line) }
          end

          @boxes.each do |source|
            INTERNAL_LINE_TYPES.each do |line_type|
              line_type.make_line(source, target) { |line| lines.add(line) }
            end
          end

          lines
        end

        count = lines.count(&:backward?)
        if backward_count.nil? || count < backward_count
          backward_count = count
          @boxes = boxes
          @lines = lines
        end
      end

      @boxes.sequence!
    end

    def attach_lines
      @lines.each(&:attach)
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

      bounding_box = [Point.new(left_edge, top_edge), Point.new(right_edge, bottom_edge)]
      @lines.each { |line| line.bounding_box(*bounding_box) }
      @lines.each { |line| line.avoid(@lines.delete(line)) }

      dx, dy = [@lines.map(&:left_edge), @lines.map(&:top_edge)].map do |set|
        set.reject(&:positive?).map(&:abs).max || 0
      end

      @boxes.each { |box| box.translate(dx + 20, dy + 20) }

      resize(right_edge + 20, bottom_edge + 20)
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
