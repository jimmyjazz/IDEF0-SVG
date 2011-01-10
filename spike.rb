#!/usr/bin/env ruby

# TODO: support backward input lines
# TODO: overlapping labels for external guidances/mechanisms
# TODO: alert reader to issues with the model, such as an input that is received but not produced by any process
# TODO: sharing external concepts (they appear twice currently)
# TODO: unbundling
# TODO: Resize boxes to accommodate anchor points
# TODO: Remove alias #process for Diagram#box

require 'forwardable'
require 'set'

class Object

  def inspect
    object_id
  end

end

module Enumerable

  def -@
    map(&:-@)
  end

end

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

    def_delegators :@items, :index, :[], :count, :each, :include?, :find, :inject, :each_with_index, :map, :any?, :group_by

    def union(other)
      self.class.new(@items.dup).union!(other)
    end
    def_delegator :self, :union, :+

    def union!(other)
      other.each { |item| @items << item }
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

    def select(&block)
      self.class.new(@items.select(&block))
    end

    def sort_by(&block)
      self.class.new(@items.sort_by(&block))
    end

    def partition(&block)
      @items.partition(&block).map { |items| self.class.new(items) }
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

    attr_reader :name
    attr_accessor :sequence

    def initialize(side, name)
      @side = side
      @name = name
      @sequence = 1
      @lines = Set.new
    end

    def attach(line)
      @lines << line
    end

    def position
      @side.anchor_point(@sequence)
    end

    def x
      position.x
    end

    def y
      position.y
    end

    def precedence
      @lines.map { |line| [line.clearance_group(@side), line.anchor_precedence(@side), line.name] }.min
    end

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
    attr_reader :source_anchor, :target_anchor

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

    def sides_to_clear
      []
    end

    def clear?(side)
      sides_to_clear.include?(side)
    end

    def clearance_precedence(side)
      raise "#{self.class.name}: No clearance precedence specified for #{side.class.name}"
    end

    def anchor_precedence(side)
      clearance_precedence(side)
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

  class ExternalLine < Line

    def anchor_precedence(side)
      []
    end

  end

  class ForwardInputLine < Line

    def initialize(*args)
      super
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.left_side.attach(self)
    end

    def sides_to_clear
      [@source.right_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        3
      when @target.left_side
        1
      else
        super
      end
    end

    def clearance_precedence(side)
      case side
      when @source.right_side
        [2, -@target.sequence, 2, -target_anchor.sequence]
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

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1+5} #{x_vertical} #{y1+10} L #{x_vertical} #{y2-10} C #{x_vertical} #{y2-5} #{x_vertical+5} #{y2} #{x_vertical+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class InternalGuidanceLine < Line

    def initialize(*args)
      super
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.top_side.attach(self)
    end

  end

  class ForwardGuidanceLine < InternalGuidanceLine

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

  class BackwardGuidanceLine < InternalGuidanceLine

    def top_edge
      y_horizontal
    end

    def right_edge
      x_vertical
    end

    def sides_to_clear
      [@target.top_side, @source.right_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        1
      when @target.top_side
        3
      else
        super
      end
    end

    def clearance_precedence(side)
      case side
      when @source.right_side
        [1, -@target.sequence, source_anchor.sequence]
      when @target.top_side
        [1, @source.sequence, -target_anchor.sequence]
      else
        super
      end
    end

    def anchor_precedence(side)
      case side
      when @target.top_side
        -super
      else
        super
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

  class ExternalInputLine < ExternalLine

    def initialize(*args)
      super
      @target_anchor = target.left_side.attach(self)
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
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class ExternalOutputLine < ExternalLine

    def initialize(*args)
      super
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

  class ExternalGuidanceLine < ExternalLine

    def initialize(*args)
      super
      clear(@target.top_side, 40)
      @target_anchor = target.top_side.attach(self)
    end

    def avoid(lines)
      while lines.any?{ |other| label.overlaps?(other.label) } do
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

    def clearance_group(side)
      case
      when @target.top_side
        2
      else
        super
      end
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1+20}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_down_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

  class ExternalMechanismLine < ExternalLine

    def initialize(*args)
      super
      clear(@target.bottom_side, 40)
      @target_anchor = target.bottom_side.attach(self)
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

    def clearance_group(side)
      case
      when @target.bottom_side
        2
      else
        super
      end
    end

    def avoid(lines)
      while lines.any?{ |other| label.overlaps?(other.label) } do
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

    def initialize(*args)
      super
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.bottom_side.attach(self)
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

  class Side

    attr_reader :margin

    def initialize(box)
      @box = box
      @anchors = ArraySet.new
      @margin = 0
    end

    # TODO: This is a fudge to make stuff work
    def each
      @anchors.each { |anchor| yield(anchor.name) }
    end

    def expects(name)
      anchor = @anchors.find { |a| a.name == name } || Anchor.new(self, name)
      @anchors << anchor
      anchor
    end

    def expects?(name)
      @anchors.any? { |a| a.name == name }
    end

    def attach(line)
      expects(line.name).tap { |anchor| anchor.attach(line) }
    end

    def sort_anchors
      @anchors = @anchors.sort_by(&:precedence)
      @anchors.each_with_index { |anchor, sequence| anchor.sequence = sequence }
    end

    def anchor_count
      @anchors.count
    end

    def x1
      @box.x1
    end

    def x2
      @box.x2
    end

    def y1
      @box.y1
    end

    def y2
      @box.y2
    end

    def width
      x2 - x1
    end

    def height
      y2 - y1
    end

    def layout(lines)
      clearance_groups = lines.select { |line| line.clear?(self) }
        .group_by { |line| line.clearance_group(self) }
        .values

      clearance_groups.each do |lines|
        lines.sort_by { |line| line.clearance_precedence(self) }
          .each_with_index { |line, index| line.clear(self, 20 + index * 20) }
      end

      line_count = clearance_groups.map(&:count).max || 0

      @margin = 20 + line_count * 20
    end

  end

  class HorizontalSide < Side

    def y
      y1
    end

    def anchor_point(n)
      baseline = x1+width/2 - 20*(@anchors.count - 1)/2
      x = baseline + n * 20
      Point.new(x, y)
    end

  end

  class VerticalSide < Side

    def x
      x1
    end

    def anchor_point(n)
      baseline = y1+height/2 - 20*(@anchors.count - 1)/2
      y = baseline + n * 20
      Point.new(x, y)
    end

  end

  class TopSide < HorizontalSide

    def y2
      @box.y1
    end

  end

  class BottomSide < HorizontalSide

    def y1
      @box.y2
    end

  end

  class LeftSide < VerticalSide

    def x2
      @box.x1
    end

  end

  class RightSide < VerticalSide

    def x1
      @box.x2
    end

  end

  class Box

    extend Forwardable

    attr_reader :name
    attr_reader :top_side, :bottom_side, :left_side, :right_side

    def initialize(name)
      @name = name
      @top_left = Point::ORIGIN
      @top_side = TopSide.new(self)
      @bottom_side = BottomSide.new(self)
      @left_side = LeftSide.new(self)
      @right_side = RightSide.new(self)
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

    def sides
      [top_side, bottom_side, left_side, right_side]
    end

    def sort_anchors
      sides.each(&:sort_anchors)
    end

    def layout(lines)
      sides.each { |side| side.layout(lines) }
      translate(0, top_side.margin)
    end

    # TODO: Wrong level of abstraction

    def receives(name)
      left_side.expects(name)
    end
    def_delegator :self, :receives, :translates

    def produces(name)
      right_side.expects(name)
    end
    def_delegator :self, :receives, :into

    def respects(name)
      top_side.expects(name)
    end

    def requires(name)
      bottom_side.expects(name)
    end

  end

  class ProcessBox < Box

    attr_accessor :sequence

    def initialize(name)
      super(name)
    end

    def precedence
      [-right_side.anchor_count, [left_side, top_side, bottom_side].map(&:anchor_count).reduce(&:+)]
    end

    def width
      180
    end

    def height
      [60, [left_side.anchor_count, right_side.anchor_count].max*20+20].max
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
      diagram.sort_boxes
      diagram.create_lines
      diagram.sort_anchors
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
      box = @boxes.find { |p| p.name == name } || ProcessBox.new(name)
      @boxes << box
      box.instance_eval(&block) if block_given?
    end
    alias_method :process, :box

    def bottom_edge
      (@boxes + @lines).map(&:bottom_edge).max || 0
    end

    def right_edge
      (@boxes + @lines).map(&:right_edge).max || 0
    end

    def sort_boxes
      @boxes = @boxes.sort_by(&:precedence)
      @boxes.each_with_index { |box, sequence| box.sequence = sequence }
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

          @boxes.after(box).each do |target|
            @lines << ForwardInputLine.new(box, target, output) if target.left_side.expects?(output)
            @lines << ForwardGuidanceLine.new(box, target, output) if target.top_side.expects?(output)
            @lines << ForwardMechanismLine.new(box, target, output) if target.bottom_side.expects?(output)
          end

          @boxes.before(box).each do |target|
            @lines << BackwardGuidanceLine.new(box, target, output) if target.top_side.expects?(output)
            @lines << BackwardMechanismLine.new(box, target, output) if target.bottom_side.expects?(output)
          end
        end
      end
    end

    def sort_anchors
      @boxes.each(&:sort_anchors)
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

diagram = eval("IDEF0.diagram #{$<.read}")
puts diagram.to_svg
