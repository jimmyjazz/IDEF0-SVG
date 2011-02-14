require_relative 'box'

module IDEF0

  class ProcessBox < Box

    attr_accessor :sequence

    def precedence
      [-right_side.anchor_count, [left_side, top_side, bottom_side].map(&:anchor_count).reduce(&:+)]
    end

    def width
      180
    end

    def height
      [60, [left_side.anchor_count, right_side.anchor_count].max*20+20].max
    end

    def after?(other)
      sequence > other.sequence
    end

    def before?(other)
      sequence < other.sequence
    end

    def to_svg
      <<-XML
<rect x='#{x1}' y='#{y1}' width='#{width}' height='#{height}' fill='none' stroke='black' />
<text text-anchor='middle' x='#{x1 + (width / 2)}' y='#{y1 + (height / 2)}'>#{name}</text>
XML
    end

  end

end
