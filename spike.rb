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

    attr_reader :name, :inputs, :outputs

    def initialize(name)
      @name = name
      @inputs = Set.new
      @outputs = Set.new
      @x1 = @y1 = 0
    end

    def receives(input)
      @inputs << input
    end

    def produces(output)
      @outputs << output
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

    def input_anchor_for(label)
      Point.new(x1, y1+height/2)
    end

    def output_anchor_for(label)
      Point.new(x2, y1+height/2)
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

  end

  class ExternalInputLine < Line

    def x1
      source.x1
    end

    def y1
      target.input_anchor_for(label).y
    end

    def x2
      target.input_anchor_for(label).x
    end

    def y2
      y1
    end

    def to_svg
      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />"
    end

  end

  class ExternalOutputLine < Line

    def x1
      source.output_anchor_for(label).x
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
      "<line x1='#{x1}' y1='#{y1}' x2='#{x2}' y2='#{y2}' stroke='black' />"
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
        end
      end
    end

    def layout
      x = x1 + 20
      y = y1 + 20
      @processes.each do |process|
        process.move_to(x, y)
        x = process.x2 + 20
        y = process.y2 + 20
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
d.process("Oversee Business Operations")
d.process("Expand The Business")
d.process("Manage Local Restaurant")
d.process("Provide Supplies")
d.process("Serve Customers") do |process|
  process.receives("Hungry Customer")
  process.produces("Satisfied Customer")
end
d.connect
d.layout
puts d.to_svg
