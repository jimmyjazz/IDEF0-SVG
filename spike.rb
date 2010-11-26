#!/usr/bin/env ruby

# TODO: support backward input lines
# TODO: overlapping labels for external guidances/mechanisms
# TODO: alert reader to issues with the model, such as an input that is received but not produced by any process
# TODO: sharing external concepts (they appear twice currently)
# TODO: unbundling
# TODO: Resize boxes to accommodate anchor points

require 'forwardable'

class Numeric

  def positive?
    self > 0
  end

end


module IDEF0

  class ArraySet

    extend Forwardable

    def initialize(items = [])
      @items = items
    end

    def_delegators :@items, :index, :[], :count, :each, :include?, :find, :inject, :each_with_index, :map, :any?

    def union(other)
      self.class.new(@items.dup).union!(other)
    end
    def_delegator :self, :union, :+

    def union!(other)
      other.each {|item| @items << item }
      self
    end

    def add(item)
      @items << item unless include?(item)
      self
    end
    def_delegator :self, :add, :<<

    def delete(item)
      self.class.new(@items.dup).delete!(item)
    end

    def delete!(item)
      @items.delete(item)
      self
    end

    def before(pattern)
      self.class.new(@items.take_while { |item| item != pattern })
    end

    def after(pattern)
      self.class.new(@items.drop_while { |item| item != pattern }[1..-1])
    end

    def reverse
      self.class.new(@items.reverse)
    end

    def select(&block)
      self.class.new(@items.select(&block))
    end

    def sort_by(&block)
      self.class.new(@items.sort_by(&block))
    end

    def partition(&block)
      @items.partition(&block).map {|items| self.class.new(items) }
    end

  end

  class Point

    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def translate(dx, dy)
      self.class.new(@x + dx, @y + dy)
    end

    ORIGIN = new(0, 0)

  end

  class Anchor

    extend Forwardable

    attr_reader :sequence

    def initialize(point, sequence)
      @point = point
      @sequence = sequence
    end

    def_delegators :@point, :x, :y

  end

  class Label

    def initialize(text, point)
      @text = text
      @point = point
    end

    def length
      @text.length * 7
    end

    def top_edge
      @point.y - 20
    end

    def bottom_edge
      @point.y
    end

    def right_edge
      left_edge + length
    end

    def overlaps?(other)
      left_edge < other.right_edge &&
      right_edge > other.left_edge &&
      top_edge < other.bottom_edge &&
      bottom_edge > other.top_edge
    end

    def to_svg
      "<text text-anchor='#{text_anchor}' x='#{@point.x}' y='#{@point.y}'>#{@text}</text>"
    end

  end

  class LeftAlignedLabel < Label

    def left_edge
      @point.x
    end

    def text_anchor
      "start"
    end

  end

  class RightAlignedLabel < Label

    def left_edge
      @point.x - length
    end

    def text_anchor
      "end"
    end

  end

  class CentredLabel < Label

    def left_edge
      @point.x - length / 2
    end

    def text_anchor
      "middle"
    end

  end

  class Line

    attr_reader :source, :target, :name

    def initialize(source, target, name)
      @source = source
      @target = target
      @name = name
      @clearance = {}
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(source_anchor.x+5, source_anchor.y-5))
    end

    def avoid(lines)
    end

    def source_anchor
      source.output_anchor_for(name)
    end

    def x1
      source_anchor.x
    end

    def y1
      source_anchor.y
    end

    def x2
      target_anchor.x
    end

    def y2
      target_anchor.y
    end

    def minimum_length
      10 + label.length
    end

    def left_edge
      [x1, x2].min
    end

    def top_edge
      [y1, y2].min
    end

    def right_edge
      [x1, x2].max
    end

    def bottom_edge
      [y1, y2].max
    end

    def upward?
      false
    end

    def sides_to_clear
      []
    end

    def clear?(side)
      sides_to_clear.include?(side)
    end

    def precedence(side)
      nil
    end

    def clear(side, distance)
      @clearance[side] = distance
    end

    def clearance_from(side)
      @clearance[side] || 0
    end

    def svg_right_arrow(x,y)
      "<polygon fill='black' stroke='black' points='#{x},#{y} #{x-6},#{y+3} #{x-6},#{y-3} #{x},#{y}' />"
    end

    def svg_down_arrow(x,y)
      "<polygon fill='black' stroke='black' points='#{x},#{y} #{x-3},#{y-6} #{x+3},#{y-6} #{x},#{y}' />"
    end

    def svg_up_arrow(x,y)
      "<polygon fill='black' stroke='black' points='#{x},#{y} #{x-3},#{y+6} #{x+3},#{y+6} #{x},#{y}' />"
    end

  end

  class ForwardInputLine < Line

    def target_anchor
      target.input_anchor_for(name)
    end

    def sides_to_clear
      [@source.right_side]
    end

    def precedence(side)
      case side
      when @source.right_side
        [2, -@target.sequence, 2, -target_anchor.sequence]
      end
    end

    def x_vertical #the x position of this line's single vertical segment
      x1 + clearance_from(@source.right_side)
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1+5} #{x_vertical} #{y1+10} L #{x_vertical} #{y2-10} C #{x_vertical} #{y2-5} #{x_vertical+5} #{y2} #{x_vertical+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class InternalGuidanceLine < Line

    def target_anchor
      target.guidance_anchor_for(name)
    end

  end

  class ForwardGuidanceLine < InternalGuidanceLine

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x2-10} #{y1} C #{x2-5} #{y1} #{x2} #{y1+5} #{x2} #{y1+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class BackwardGuidanceLine < InternalGuidanceLine

    def upward?
      true
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

    def precedence(side)
      case side
      when @target.top_side
        [1, @source.sequence, -target_anchor.sequence]
      when @source.right_side
        [1, -@target.sequence, source_anchor.sequence]
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

  class ExternalInputLine < Line

    def target_anchor
      target.input_anchor_for(name)
    end

    def x1
      [source.x1, x2 - minimum_length].min
    end

    def y1
      target_anchor.y
    end

    def y2
      y1
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(source.x1+5, y1-5))
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class ExternalOutputLine < Line

    def x2
      [x1 + minimum_length, target.x2].max
    end

    def y2
      y1
    end

    def label
      RightAlignedLabel.new(@name, Point.new(target.x2-5, y2-5))
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class ExternalGuidanceLine < Line

    def initialize(*args)
      super
      clear(@target.top_side, 40)
    end

    def target_anchor
      target.guidance_anchor_for(name)
    end

    def avoid(lines)
      while lines.any?{|other| label.overlaps?(other.label)} do
        clear(@target.top_side, 20+clearance_from(@target.top_side))
      end
    end

    def x1
      target_anchor.x
    end

    def y1
      [source.y1, y2 - clearance_from(@target.top_side)].min
    end

    def x2
      x1
    end

    def label
      CentredLabel.new(@name, Point.new(x1, y1+20-5))
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1+20}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class ExternalMechanismLine < Line

    def initialize(*args)
      super
      clear(@target.bottom_side, 40)
    end

    def target_anchor
      target.mechanism_anchor_for(name)
    end

    def x1
      target_anchor.x
    end

    def y1
      [source.y2, y2+clearance_from(@target.bottom_side)].max
    end

    def x2
      x1
    end

    def label
      CentredLabel.new(@name, Point.new(x1, y1-5))
    end

    def avoid(lines)
      while lines.any?{|other| label.overlaps?(other.label)} do
        clear(@target.bottom_side, 20+clearance_from(@target.bottom_side))
      end
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1-20}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_up_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class InternalMechanismLine < Line

    def target_anchor
      target.mechanism_anchor_for(name)
    end

    def x_vertical
      x1 + clearance_from(@source.right_side)
    end

    def bottom_edge
      y_horizontal
    end

  end

  class ForwardMechanismLine < InternalMechanismLine

    def y_horizontal
      y2 + clearance_from(@target.bottom_side)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x_vertical+10, y_horizontal-5))
    end

    def sides_to_clear
      [@source.right_side, @target.bottom_side]
    end

    def precedence(side)
      case side
      when @target.bottom_side
        [1, -@source.sequence, target_anchor.sequence]
      when @source.right_side
        [2, -@target.sequence, 1, -target_anchor.sequence]
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

  class BackwardMechanismLine < InternalMechanismLine

    def y_horizontal
      @source.bottom_edge + clearance_from(@source.bottom_side)
    end

    def right_edge
      x_vertical
    end

    def sides_to_clear
      [@source.right_side, @source.bottom_side]
    end

    def precedence(side)
      case side
      when @source.bottom_side
        [2, -@target.sequence, -target_anchor.sequence]
      when @source.right_side
        [1, -@target.sequence, -target_anchor.sequence]
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

  class Side

    def initialize(process, direction)
      @process = process
      @direction = direction
    end

  end

  class ProcessBox

    attr_reader :name
    attr_reader :inputs, :outputs, :guidances, :mechanisms
    attr_reader :top_side, :bottom_side, :left_side, :right_side

    def initialize(name)
      @name = name
      @top_left = Point::ORIGIN
      [:top, :bottom, :left, :right].each do |direction|
        instance_variable_set("@#{direction}_side", Side.new(self,direction))
      end
      @inputs = ArraySet.new
      @outputs = ArraySet.new
      @guidances = ArraySet.new
      @mechanisms = ArraySet.new
    end

    def move_to(top_left)
      @top_left = top_left
    end

    def translate(dx, dy)
      move_to(@top_left.translate(dx, dy))
    end

    def x1
      @top_left.x
    end

    def y1
      @top_left.y
    end

    def x2
      x1 + width
    end

    def y2
      y1 + height
    end

    def right_edge
      x2
    end

    def bottom_edge
      y2
    end

    def receives(input)
      @inputs << input
    end

    def receives?(input)
      @inputs.include?(input)
    end

    def produces(output)
      @outputs << output
    end

    def produces?(guidance)
      @outputs.include?(guidance)
    end

    def respects(guidance)
      @guidances << guidance
    end

    def respects?(guidance)
      @guidances.include?(guidance)
    end

    def requires(mechanism)
      @mechanisms << mechanism
    end

    def requires?(mechanism)
      @mechanisms.include?(mechanism)
    end

  end

  class ChildProcessBox < ProcessBox

    attr_reader :sequence

    def initialize(name, sequence)
      super(name)
      @sequence = sequence
    end

    def width
      180
    end

    def height
      [60, [@inputs.count, @outputs.count].max*20+20].max
    end

    def vertical_anchor(set, x, name)
      baseline = y1+height/2 - 20*(set.count - 1)/2
      index = set.index(name)
      y = baseline + index * 20
      Anchor.new(Point.new(x, y), index)
    end

    def horizontal_anchor(set, name, y)
      baseline = x1+width/2 - 20*(set.count - 1)/2
      index = set.index(name)
      x = baseline + index * 20
      Anchor.new(Point.new(x, y), index)
    end

    def input_anchor_for(name)
      vertical_anchor(@inputs, x1, name)
    end

    def output_anchor_for(name)
      vertical_anchor(@outputs, x2, name)
    end

    def guidance_anchor_for(name)
      horizontal_anchor(@guidances, name, y1)
    end

    def mechanism_anchor_for(name)
      horizontal_anchor(@mechanisms, name, y2)
    end

    def to_svg
      <<-XML
<rect x='#{x1}' y='#{y1}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x1 + (width / 2)}' y='#{y1 + (height / 2)}'>#{name}</text>
XML
    end

  end

  def self.diagram(name, &block)
    Diagram.new(name).tap do |diagram|
      diagram.instance_eval(&block)
      diagram.connect
      diagram.layout
    end
  end

  class Diagram < ProcessBox

    attr_reader :width, :height

    def initialize(name)
      super
      @processes = ArraySet.new
      @lines = ArraySet.new
      @width = @height = 0
    end

    def resize(width, height)
      @width = width
      @height = height
    end

    def process(name, &block)
      process = @processes.find { |p| p.name == name } || ChildProcessBox.new(name, @processes.count)
      @processes << process
      process.instance_eval(&block) if block_given?
    end

    def bottom_edge
      (@processes + @lines).map(&:bottom_edge).max || 0
    end

    def right_edge
      (@processes + @lines).map(&:right_edge).max || 0
    end

    def connect
      @lines = ArraySet.new
      @processes.each do |process|
        process.inputs.each do |input|
          @lines << ExternalInputLine.new(self, process, input) if receives?(input)
        end

        process.guidances.each do |guidance|
          @lines << ExternalGuidanceLine.new(self, process, guidance) if respects?(guidance)
        end

        process.mechanisms.each do |mechanism|
          @lines << ExternalMechanismLine.new(self, process, mechanism) if requires?(mechanism)
        end

        process.outputs.each do |output|
          @lines << ExternalOutputLine.new(process, self, output) if produces?(output)

          @processes.after(process).each do |target|
            @lines << ForwardInputLine.new(process, target, output) if target.receives?(output)
            @lines << ForwardGuidanceLine.new(process, target, output) if target.respects?(output)
            @lines << ForwardMechanismLine.new(process, target, output) if target.requires?(output)
          end

          @processes.before(process).each do |target|
            @lines << BackwardGuidanceLine.new(process, target, output) if target.respects?(output)
            @lines << BackwardMechanismLine.new(process, target, output) if target.requires?(output)
          end
        end
      end
    end

    def layout
      @processes.inject(@top_left) do |point, process|
        top_lines = @lines.select {|line| line.clear?(process.top_side) }
        top_margin = top_lines.count * 20
        top_lines.sort_by {|line| line.precedence(process.top_side)}.each_with_index do |line, index|
          line.clear(process.top_side, 20+index*20)
        end

        right_lines = @lines.select {|line| line.clear?(process.right_side) }
        right_up_lines, right_down_lines = right_lines.partition(&:upward?)

        right_margin = 20 + 20 * [right_up_lines.count, right_down_lines.count].max

        right_up_lines.sort_by {|line| line.precedence(process.right_side)}.each_with_index do |line, index|
          line.clear(process.right_side, 20+index*20)
        end

        right_down_lines.sort_by {|line| line.precedence(process.right_side)}.each_with_index do |line, index|
          line.clear(process.right_side, 20+index*20)
        end

        bottom_lines = @lines.select {|line| line.clear?(process.bottom_side) }
        bottom_margin = 20 + bottom_lines.count * 20
        bottom_lines.sort_by {|line| line.precedence(process.bottom_side)}.each_with_index do |line, index|
          line.clear(process.bottom_side, 20+index*20)
        end

        process.move_to(point.translate(0, top_margin))

        Point.new(process.x2 + right_margin, process.y2 + bottom_margin)
      end

      @lines.each do |line|
        line.avoid(@lines.delete(line))
      end

      dx, dy = [@lines.map(&:left_edge), @lines.map(&:top_edge)].map do |set|
        set.reject(&:positive?).map(&:abs).max || 0
      end

      @processes.each { |process| process.translate(dx, dy) }

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
    #{generate_processes}
    #{generate_lines}
  </g>
</svg>
XML
    end

    def generate_processes
      @processes.map(&:to_svg).join("\n")
    end

    def generate_lines
      @lines.map(&:to_svg).join("\n")
    end

  end

end

diagram = IDEF0.diagram("Operate Ben's Burgers") do

  receives("Hungry Customer")
  produces("Satisfied Customer")
  requires("Original Facility")
  respects("Business Plan")
  respects("Business Plan 2")
  respects("Short Term Goals")
  respects("Prices of Food and Supplies")

  process("Oversee Business Operations") do
    receives("Hungry Customer")
    produces("Communications to Local Managers")
    produces("Approvals and Commentary")
    respects("Business Plan")
    respects("Business Plan 2")
    respects("Communications with Top Management")
    respects("Expansion Plans and New Ideas")
  end

  process("Expand The Business") do
    respects("Approvals and Commentary")
    respects("Suggestions for Expansion")
    produces("Expansion Plans and New Ideas")
    produces("Transport")
    produces("New Facility")
  end

  process("Manage Local Restaurant") do
    respects("Communications to Local Managers")
    respects("Short Term Goals")
    respects("Status of Local Operations")
    respects("Prices and Invoices")
    produces("Suggestions for Expansion")
    produces("Communications with Top Management")
    produces("Local Management Communications")
    produces("Orders and Payments")
    produces("Finance System")
    requires("Uniforms")
    requires("Stationary")
  end

  process("Provide Supplies") do
    produces("Prices and Invoices")
    produces("Ingredients")
    produces("Manchester")
    produces("Uniforms")
    produces("Stationary")
    respects("Orders and Payments")
    respects("Prices of Food and Supplies")
    requires("Finance System")
    requires("Transport")
  end

  process("Serve Customers") do
    receives("Ingredients")
    receives("Hungry Customer")
    respects("Local Management Communications")
    produces("Status of Local Operations")
    produces("Satisfied Customer")
    requires("Manchester")
    requires("Uniforms")
    requires("New Facility")
    requires("Original Facility")
  end

end

puts diagram.to_svg
