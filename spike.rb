#!/usr/bin/env ruby

module IDEF0

  class Process

    def initialize(name)
      @name = name
    end

    def width
      180
    end

    def height
      60
    end

    def to_svg(x, y)
      <<-XML
<rect x='#{x}' y='#{y}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x + (width / 2)}' y='#{y + (height / 2)}'>#{@name}</text>
XML
    end

  end

  class Diagram

    def initialize
      @processes = []
    end

    def process(name)
      @processes << Process.new(name)
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
    #{render_diagram_body}
  </g>
</svg>
XML
    end

    def render_diagram_body
      x = 0
      y = 0

      @processes.map do |process|
        output = process.to_svg(x, y)
        x += process.width + 20
        y += process.height + 20
        output
      end.join("\n")
    end
  end

end

d = IDEF0::Diagram.new
d.process("Oversee Business Operations")
d.process("Expand The Business")
d.process("Manage Local Restaurant")
d.process("Provide Supplies")
d.process("Serve Customers")
puts d.to_svg
