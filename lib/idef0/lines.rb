require_relative 'collection_negation'
require_relative 'point'
require_relative 'labels'

module IDEF0

  class Line

    attr_reader :source, :target, :name
    attr_reader :source_anchor, :target_anchor

    def initialize(source, target, name)
      @source = source
      @target = target
      @name = name
      @clearance = {}
    end

    def backward?
      self.class.name =~ /::Backward.*$/
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

    def self.make_line(source, target)
      return unless source.before?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.left_side.expects?(name)
      end
    end

    def connect
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

    def connect
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.top_side.attach(self)
    end

  end

  class ForwardGuidanceLine < InternalGuidanceLine

    def self.make_line(source, target)
      return unless source.before?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.top_side.expects?(name)
      end
    end

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

    def self.make_line(source, target)
      return unless source.after?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.top_side.expects?(name)
      end
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

    def self.make_line(source, target)
      source.left_side.each do |name|
        yield(new(source, target, name)) if target.left_side.expects?(name)
      end
    end

    def connect
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

    def self.make_line(target, source)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.right_side.expects?(name)
      end
    end

    def connect
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

    def self.make_line(source, target)
      source.top_side.each do |name|
        yield(new(source, target, name)) if target.top_side.expects?(name)
      end
    end

    def initialize(*args)
      super
      clear(@target.top_side, 40)
    end

    def connect
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

    def self.make_line(source, target)
      source.bottom_side.each do |name|
        yield(new(source, target, name)) if target.bottom_side.expects?(name)
      end
    end

    def initialize(*args)
      super
      clear(@target.bottom_side, 40)
    end

    def connect
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

    def connect
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

    def self.make_line(source, target)
      return unless source.before?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.bottom_side.expects?(name)
      end
    end

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

    def self.make_line(source, target)
      return unless source.after?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.bottom_side.expects?(name)
      end
    end

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

  class BackwardInputLine < Line

    def self.make_line(source, target)
      return unless source.after?(target)
      source.right_side.each do |name|
        yield(new(source, target, name)) if target.left_side.expects?(name)
      end
    end

    def connect
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.left_side.attach(self)
    end

    def sides_to_clear
      [@source.right_side, @source.bottom_side, @target.left_side]
    end

    def clearance_group(side)
      case side
      when @source.right_side
        3
      when @source.bottom_side
        1
      when @target.left_side
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
      when @target.left_side
        [1]
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

    def y_horizontal
      @source.bottom_edge + clearance_from(@source.bottom_side)
    end

    def label
      LeftAlignedLabel.new(@name, Point.new(x2+10, y_horizontal-5))
    end

    def to_svg
      <<-XML
<path stroke='black' fill='none' d='M #{x1} #{y1} L #{x_vertical-10} #{y1} C #{x_vertical-5} #{y1} #{x_vertical} #{y1+5} #{x_vertical} #{y1+10} L #{x_vertical} #{y_horizontal-10} C #{x_vertical} #{y_horizontal-5} #{x_vertical-5} #{y_horizontal} #{x_vertical-10} #{y_horizontal} L #{x2+10} #{y_horizontal} C #{x2+5} #{y_horizontal} #{x2} #{y_horizontal-5} #{x2} #{y_horizontal-10} L #{x2} #{y2}' />
#{svg_up_arrow(x2, y2)}
#{label.to_svg}
XML
    end

  end

end
