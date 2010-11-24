#!/usr/bin/env ruby

# TODO: unbundling
# TODO: overlapping objects
# TODO: sharing external concepts (they appear twice currently)
# TODO: Resize boxes to accommodate anchor points

require 'forwardable'

module IDEF0

  class OrderedSet

    extend Forwardable

    include Enumerable

    def initialize(items = [])
      @items = items
    end

    def add(item)
      @items << item unless include?(item)
    end
    def_delegator :self, :add, :<<

    def_delegator :@items, :index
    def_delegator :@items, :each
    def_delegator :@items, :[]
    def_delegator :@items, :size

    def before(pattern)
      self.class.new(@items.take_while { |item| item != pattern })
    end

    def after(pattern)
      self.class.new(@items.drop_while { |item| item != pattern }[1..-1])
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

  end

  class Line

    attr_reader :source, :target, :name

    def initialize(source, target, name)
      @source = source
      @target = target
      @name = name
    end

    def minimum_length
      10 + name.length * 7
    end

    def down_from?(process)
      false
    end

    def up_from?(process)
      false
    end

    def svg_right_arrow(x,y)
      <<-XML
<polygon fill='black' stroke='black' points='#{x},#{y} #{x-6},#{y+3} #{x-6},#{y-3} #{x},#{y}' />
XML
    end

    def svg_down_arrow(x,y)
      <<-XML
<polygon fill='black' stroke='black' points='#{x},#{y} #{x-3},#{y-6} #{x+3},#{y-6} #{x},#{y}' />
XML
    end

    def svg_up_arrow(x,y)
      <<-XML
<polygon fill='black' stroke='black' points='#{x},#{y} #{x-3},#{y+6} #{x+3},#{y+6} #{x},#{y}' />
XML
    end

  end

  class ForwardInputLine < Line

    def x1
      source.output_anchor_for(name).x
    end

    def y1
      source.output_anchor_for(name).y
    end

    def x2
      target.input_anchor_for(name).x
    end

    def y2
      target.input_anchor_for(name).y
    end

    def down_from?(process)
      @source == process
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+20-10} #{y1} C #{x1+20-5} #{y1} #{x1+20} #{y1+5} #{x1+20} #{y1+10} L #{x1+20} #{y2-10} C #{x1+20} #{y2-5} #{x1+20+5} #{y2} #{x1+20+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class InternalGuidanceLine < Line

    def x1
      source.output_anchor_for(name).x
    end

    def y1
      source.output_anchor_for(name).y
    end

    def x2
      target.guidance_anchor_for(name).x
    end

    def y2
      target.guidance_anchor_for(name).y
    end

  end

  class ForwardGuidanceLine < InternalGuidanceLine

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x2-10} #{y1} C #{x2-5} #{y1} #{x2} #{y1+5} #{x2} #{y1+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class BackwardGuidanceLine < InternalGuidanceLine

    def up_from?(process)
      @source == process
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+20-10} #{y1} C #{x1+20-5} #{y1} #{x1+20} #{y1-5} #{x1+20} #{y1-10} L #{x1+20} #{y2-20+10} C #{x1+20} #{y2-20+5} #{x1+20-5} #{y2-20} #{x1+20-10} #{y2-20} L #{x2+10} #{y2-20} C #{x2+5} #{y2-20} #{x2} #{y2-20+5} #{x2} #{y2-20+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
<text text-anchor='end' x='#{x1}' y='#{y2-20-5}'>#{name}</text>
XML
    end

  end

  class ExternalInputLine < Line

    def x1
      x2 - minimum_length
    end

    def y1
      target.input_anchor_for(name).y
    end

    def x2
      target.input_anchor_for(name).x
    end

    def y2
      y1
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class ExternalOutputLine < Line

    def x1
      source.output_anchor_for(name).x
    end

    def y1
      source.output_anchor_for(name).y
    end

    def x2
      x1 + minimum_length
    end

    def y2
      y1
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='end' x='#{x2-5}' y='#{y2-5}'>#{name}</text>
XML
    end

  end

  class ExternalGuidanceLine < Line

    def x1
      target.guidance_anchor_for(name).x
    end

    def y1
      y2-40+20
    end

    def x2
      x1
    end

    def y2
      target.guidance_anchor_for(name).y
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_down_arrow(x2, y2)}
<text text-anchor='middle' x='#{x1}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class ExternalMechanismLine < Line

    def x1
      target.mechanism_anchor_for(name).x
    end

    def y1
      y2+40-20
    end

    def x2
      x1
    end

    def y2
      target.mechanism_anchor_for(name).y
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_up_arrow(x2, y2)}
<text text-anchor='middle' x='#{x1}' y='#{y1+20}'>#{name}</text>
XML
    end

  end

  class InternalMechanismLine < Line

    def x1
      source.output_anchor_for(name).x
    end

    def y1
      source.output_anchor_for(name).y
    end

    def x2
      target.mechanism_anchor_for(name).x
    end

    def y2
      target.mechanism_anchor_for(name).y
    end

    def down_from?(process)
      @source == process
    end

  end

  class ForwardMechanismLine < InternalMechanismLine

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+20-10} #{y1} C #{x1+20-5} #{y1} #{x1+20} #{y1+5} #{x1+20} #{y1+10} L #{x1+20} #{y2+20-10} C #{x1+20} #{y2+20-5} #{x1+20+5} #{y2+20} #{x1+20+10} #{y2+20}  L #{x2-10} #{y2+20} C #{x2-5} #{y2+20} #{x2} #{y2+20-5} #{x2} #{y2+20-10} L #{x2} #{y2}' />
#{svg_up_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+10+10+5}' y='#{y2+20-5}'>#{name}</text>
XML
    end

  end

  class BackwardMechanismLine < InternalMechanismLine

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+20-10} #{y1} C #{x1+20-5} #{y1} #{x1+20} #{y1+5} #{x1+20} #{y1+10} L #{x1+20} #{source.y2+20-10} C #{x1+20} #{source.y2+20-5} #{x1+20-5} #{source.y2+20} #{x1+20-10} #{source.y2+20} L #{x2+10} #{source.y2+20} C #{x2+5} #{source.y2+20} #{x2} #{source.y2+20-5} #{x2} #{source.y2+20-10} L #{x2} #{y2}' />
#{svg_up_arrow(x2, y2)}
<text text-anchor='end' x='#{x1+10-10-5}' y='#{source.y2+20-5}'>#{name}</text>
XML
    end

  end

  class ProcessBox

    attr_reader :name, :x1, :y1, :inputs, :outputs, :guidances, :mechanisms

    def initialize(name)
      @name = name
      @x1 = @y1 = 0
      @inputs = OrderedSet.new
      @outputs = OrderedSet.new
      @guidances = OrderedSet.new
      @mechanisms = OrderedSet.new
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

    def x2
      x1 + width
    end

    def y2
      y1 + height
    end

  end

  class ChildProcessBox < ProcessBox

    def move_to(point)
      @x1 = point.x
      @y1 = point.y
    end

    def width
      180
    end

    def height
      60
    end

    def input_baseline
      y1+height/2 - 20*(@inputs.size - 1)/2
    end

    def input_anchor_for(name)
      input_index = @inputs.index(name)
      y = input_baseline + input_index * 20
      Point.new(x1, y)
    end

    def output_baseline
      y1+height/2 - 20*(@outputs.size - 1)/2
    end

    def output_anchor_for(name)
      index = @outputs.index(name)
      y = output_baseline + index * 20
      Point.new(x2, y)
    end

    def guidance_baseline
      x1+width/2 - 20*(@guidances.size - 1)/2
    end

    def guidance_anchor_for(name)
      index = @guidances.index(name)
      x = guidance_baseline + index * 20
      Point.new(x, y1)
    end

    def mechanism_baseline
      x1+width/2 - 20*(@mechanisms.size - 1)/2
    end

    def mechanism_anchor_for(name)
      index = @mechanisms.index(name)
      x = mechanism_baseline + index * 20
      Point.new(x, y2)
    end

    def to_svg
      <<-XML
<rect x='#{x1}' y='#{y1}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x1 + (width / 2)}' y='#{y1 + (height / 2)}'>#{name}</text>
XML
    end

  end

  class Diagram < ProcessBox

    def initialize(name)
      super
      @processes = OrderedSet.new
      @lines = OrderedSet.new
    end

    def process(name)
      p = @processes.find { |p| p.name == name } || ChildProcessBox.new(name)
      @processes << p
      yield(p) if block_given?
    end

    def width
      @processes.map(&:x2).max
    end

    def height
      @processes.map(&:y2).max
    end

    def connect
      @lines = OrderedSet.new
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
      @processes.inject(Point.new(0, 0)) do |point, process|
        process.move_to(point)

        down_lines = @lines.select {|line| line.down_from?(process) }
        down_margin = 20 + down_lines.count * 20
        up_lines = @lines.select {|line| line.up_from?(process) }
        up_margin = 20 + up_lines.count * 20

        right_margin = [down_margin, up_margin].max

        point.translate(process.width + right_margin, process.height)
      end
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

d = IDEF0::Diagram.new("Ben's Burgers")

d.receives("Hungry Customer")
d.produces("Satisfied Customer")
d.requires("Original Facility")
d.respects("Business Plan")
d.respects("Short Term Goals")
d.respects("Prices of Food and Supplies")

d.process("Oversee Business Operations") do |process|
  process.produces("Communications to Local Managers")
  process.produces("Approvals and Commentary")
  process.respects("Business Plan")
  process.respects("Communications with Top Management")
  process.respects("Expansion Plans and New Ideas")
end

d.process("Expand The Business") do |process|
  process.respects("Approvals and Commentary")
  process.respects("Suggestions for Expansion")
  process.produces("Expansion Plans and New Ideas")
  process.produces("New Facility")
end

d.process("Manage Local Restaurant") do |process|
  process.respects("Communications to Local Managers")
  process.respects("Short Term Goals")
  process.respects("Status of Local Operations")
  process.respects("Prices and Invoices")
  process.produces("Local Management Communications")
  process.produces("Suggestions for Expansion")
  process.produces("Communications with Top Management")
  process.produces("Orders and Payments")
  process.requires("Utensils")
end

d.process("Provide Supplies") do |process|
  process.produces("Prices and Invoices")
  process.produces("Ingredients")
  process.produces("Utensils")
  process.respects("Orders and Payments")
  process.respects("Prices of Food and Supplies")
end

d.process("Serve Customers") do |process|
  process.receives("Ingredients")
  process.receives("Hungry Customer")
  process.respects("Local Management Communications")
  process.produces("Status of Local Operations")
  process.produces("Satisfied Customer")
  process.requires("New Facility")
  process.requires("Original Facility")
end
d.connect
d.layout
puts d.to_svg
