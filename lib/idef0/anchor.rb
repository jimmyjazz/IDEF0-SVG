require 'set'

module IDEF0

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

    def attached?
      !@lines.empty?
    end

    def precedence
      raise "Unattached anchor on #{@side.name}: #{@name.inspect}" if @lines.empty?
      @lines.map { |line| [line.clearance_group(@side), line.anchor_precedence(@side), line.name] }.min || [0]
    end

  end

end