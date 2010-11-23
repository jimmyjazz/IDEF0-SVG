#!/usr/bin/env ruby

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

  end

  class ForwardOutputInputLine < Line

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

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+10-10} #{y1} C #{x1+10-5} #{y1} #{x1+10} #{y1+5} #{x1+10} #{y1+10} L #{x1+10} #{y2-10} C #{x1+10} #{y2-5} #{x1+10+5} #{y2} #{x1+10+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class OutputGuidanceLine < Line

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

  class ForwardOutputGuidanceLine < OutputGuidanceLine

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x2-10} #{y1} C #{x2-5} #{y1} #{x2} #{y1+5} #{x2} #{y1+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{name}</text>
XML
    end

  end

  class BackwardOutputGuidanceLine < OutputGuidanceLine

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
      source.x1
    end

    def y1
      target.input_anchor_for(name).y
    end

    def x2
      [x1 + minimum_length, target.input_anchor_for(name).x].max
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
      [x2 - minimum_length, source.output_anchor_for(name).x].min
    end

    def y1
      source.output_anchor_for(name).y
    end

    def x2
      target.x2
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

  class ProcessBox

    attr_reader :name, :x1, :y1, :inputs, :outputs, :guidances

    def initialize(name)
      @name = name
      @x1 = @y1 = 0
      @inputs = OrderedSet.new
      @outputs = OrderedSet.new
      @guidances = OrderedSet.new
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

    def x2
      x1 + width
    end

    def y2
      y1 + height
    end

  end

  class ChildProcessBox < ProcessBox

    def move_to(x, y)
      @x1 = x
      @y1 = y
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
      @processes.map(&:x2).max + 40
    end

    def height
      @processes.map(&:y2).max + 40
    end

    def connect
      @lines = OrderedSet.new
      @processes.each do |process|
        process.inputs.each do |input|
          @lines << ExternalInputLine.new(self, process, input) if receives?(input)
        end

        process.outputs.each do |output|
          @lines << ExternalOutputLine.new(process, self, output) if produces?(output)
          @processes.after(process).each do |target|
            @lines << ForwardOutputInputLine.new(process, target, output) if target.receives?(output)
            @lines << ForwardOutputGuidanceLine.new(process, target, output) if target.respects?(output)
          end
          @processes.before(process).each do |target|
            @lines << BackwardOutputGuidanceLine.new(process, target, output) if target.respects?(output)
          end
        end
      end
    end

    def layout
      x = x1 + 20
      y = y1 + 40
      @processes.each do |process|
        process.move_to(x, y)
        x = process.x2 + 30
        y = process.y2 + 30
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

d.process("Oversee Business Operations") do |process|
  process.receives("Hungry Customer")
  process.respects("Expansion Plans and New Ideas")
  process.produces("Communications to Local Managers")
  process.produces("Approvals and Commentary")
end

d.process("Expand The Business") do |process|
  process.respects("Approvals and Commentary")
  process.produces("Expansion Plans and New Ideas")
end

d.process("Manage Local Restaurant") do |process|
  process.respects("Communications to Local Managers")
  process.respects("Status of Local Operations")
  process.respects("Prices and Invoices")
  process.produces("Local Management Communications")
end

d.process("Provide Supplies") do |process|
  process.produces("Prices and Invoices")
  process.produces("Ingredients")
end

d.process("Serve Customers") do |process|
  process.receives("Ingredients")
  process.receives("Hungry Customer")
  process.respects("Local Management Communications")
  process.produces("Status of Local Operations")
  process.produces("Satisfied Customer")
end
d.connect
d.layout
puts d.to_svg
