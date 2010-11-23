#!/usr/bin/env ruby

require 'set'

module IDEF0

  class Point

      attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

  end

  module Box

    attr_reader :x1, :y1

    def x2
      x1 + width
    end

    def y2
      y1 + height
    end

  end

  class ProcessBox

    include Box

    attr_reader :name, :inputs, :outputs, :guidances

    def initialize(name)
      @name = name
      @inputs = Set.new
      @outputs = Set.new
      @guidances = Set.new
      @x1 = @y1 = 0
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

    def respects(guidance)
      @guidances << guidance
    end

    def respects?(guidance)
      @guidances.include?(guidance)
    end

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

    def input_anchor_for(label)
      input_index = @inputs.sort.index(label)
      y = input_baseline + input_index * 20
      Point.new(x1, y)
    end

    def output_baseline
      y1+height/2 - 20*(@outputs.size - 1)/2
    end

    def output_anchor_for(label)
      index = @outputs.sort.index(label)
      y = output_baseline + index * 20
      Point.new(x2, y)
    end

    def guidance_baseline
      x1+width/2 - 20*(@guidances.size - 1)/2
    end

    def guidance_anchor_for(label)
      index = @guidances.sort.index(label)
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

  class Line

    attr_reader :source, :target, :label

    def initialize(source, target, label)
      @source = source
      @target = target
      @label = label
    end

    def minimum_length
      10 + label.length * 7
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
      source.output_anchor_for(label).x
    end

    def y1
      source.output_anchor_for(label).y
    end

    def x2
      target.input_anchor_for(label).x
    end

    def y2
      target.input_anchor_for(label).y
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x1+10} #{y1} L #{x1+10} #{y2} L #{x2} #{y2}' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{label}</text>
XML
    end

  end

  class ForwardOutputGuidanceLine < Line

    def x1
      source.output_anchor_for(label).x
    end

    def y1
      source.output_anchor_for(label).y
    end

    def x2
      target.guidance_anchor_for(label).x
    end

    def y2
      target.guidance_anchor_for(label).y
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x2-10} #{y1} C #{x2-5} #{y1} #{x2} #{y1+5} #{x2} #{y1+10} L #{x2} #{y2}' />
#{svg_down_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{label}</text>
XML
    end

  end

  class ExternalInputLine < Line

    def x1
      source.x1
    end

    def y1
      target.input_anchor_for(label).y
    end

    def x2
      [x1 + minimum_length, target.input_anchor_for(label).x].max
    end

    def y2
      y1
    end

    def to_svg
      <<-XML
<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />
#{svg_right_arrow(x2, y2)}
<text text-anchor='start' x='#{x1+5}' y='#{y1-5}'>#{label}</text>
XML
    end

  end

  class ExternalOutputLine < Line

    def x1
      [x2 - minimum_length, source.output_anchor_for(label).x].min
    end

    def y1
      source.output_anchor_for(label).y
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
<text text-anchor='end' x='#{x2-5}' y='#{y2-5}'>#{label}</text>
XML
    end

  end

  class Diagram

    include Box

    def initialize
      @processes = []
      @inputs = Set.new
      @outputs = Set.new
      @lines = Set.new
      @x1 = @y1 = 0
    end

    def process(name)
      p = ProcessBox.new(name)
      yield(p) if block_given?
      @processes << p
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

    def produces?(output)
      @outputs.include?(output)
    end

    def each_process_forward_of(process, &block)
      @processes[@processes.index(process)+1..-1].each(&block)
    end

    def width
      @processes.map(&:x2).max + 40
    end

    def height
      @processes.map(&:y2).max + 40
    end

    def connect
      @lines = Set.new
      @processes.each do |process|
        process.inputs.each do |input|
          @lines << ExternalInputLine.new(self, process, input) if receives?(input)
        end

        process.outputs.each do |output|
          @lines << ExternalOutputLine.new(process, self, output) if produces?(output)
          each_process_forward_of(process) do |target|
            @lines << ForwardOutputInputLine.new(process, target, output) if target.receives?(output)
            @lines << ForwardOutputGuidanceLine.new(process, target, output) if target.respects?(output)
          end
        end
      end
    end

    def layout
      x = x1 + 20
      y = y1 + 20
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

d = IDEF0::Diagram.new
d.receives("Hungry Customer")
d.produces("Satisfied Customer")
d.process("Oversee Business Operations") do |process|
  process.receives("Hungry Customer")
  process.produces("Communications to Local Managers")
  process.produces("Approvals and Commentary")
end
d.process("Expand The Business") do |process|
  process.respects("Approvals and Commentary")
end
d.process("Manage Local Restaurant") do |process|
  process.respects("Communications to Local Managers")
  process.produces("Local Management Communications")
end

d.process("Provide Supplies") do |process|
  process.produces("Ingredients")
end
d.process("Serve Customers") do |process|
  process.receives("Hungry Customer")
  process.receives("Ingredients")
  process.respects("Local Management Communications")
  process.produces("Satisfied Customer")
end
d.connect
d.layout
puts d.to_svg
