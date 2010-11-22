#!/usr/bin/env ruby

require 'set'

module IDEF0

  class Process

    attr_reader :x, :y
    attr_reader :inputs, :outputs

    def initialize(name)
      @name = name
      @inputs = Set.new
      @outputs = Set.new
      @x = @y = 0
    end

    def receives(input)
      @inputs << input
    end

    def produces(output)
      @outputs << output
    end

    def move_to(x, y)
      @x = x
      @y = y
    end

    def width
      180
    end

    def height
      60
    end

    def to_svg
      <<-XML
<rect x='#{x}' y='#{y}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x + (width / 2)}' y='#{y + (height / 2)}'>#{@name}</text>
XML
    end

  end

  class Line

    attr_reader :source, :target

    def initialize(source, target)
      @source = source
      @target = target
    end

  end

  class ExternalInputLine < Line

    def to_svg
      <<-XML
<line x1='0' y1='#{target.y}' x2='#{target.x}' y2='#{target.y}' stroke='black' />
XML
    end

  end

  class ExternalOutputLine < Line

    def to_svg
      <<-XML
<line x1='#{source.x + source.width}' y1='#{source.y}' x2='1024' y2='#{source.y}' stroke='black' />
XML
    end

  end

  class Diagram

    def initialize
      @processes = []
      @inputs = Set.new
      @outputs = Set.new
      @lines = Set.new
    end

    def process(name)
      p = Process.new(name)
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

    def connect
      @lines = Set.new
      @processes.each do |process|
        process.inputs.each do |input|
          if receives?(input)
            @lines << ExternalInputLine.new(input, process)
          end
        end

        process.outputs.each do |output|
          if produces?(output)
            @lines << ExternalOutputLine.new(process, output)
          end
        end
      end
    end

    def layout
      x = 0
      y = 0

      @processes.each do |process|
        process.move_to(x, y)
        x += process.width + 20
        y += process.height + 20
      end
    end

    def to_svg
      <<-XML
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"
 "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [
 <!ATTLIST svg xmlns:xlink CDATA #FIXED "http://www.w3.org/1999/xlink">
]>
<svg width='1024pt' height='768pt'>
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
