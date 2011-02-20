require_relative 'array_set'
require_relative 'statement'
require_relative 'diagram'

module IDEF0

  class Process

    attr_reader :name

    def self.parse(io)
      statements = IDEF0::Statement.parse(io)

      processes = Hash.new { |hash, name| hash[name] = IDEF0::Process.new(name) }

      statements.each do |statement|
        process = processes[statement.subject]
        case statement.predicate
        when "is composed of"
          child = processes[statement.object]
          process.add_child(child)
        when "receives", "produces", "respects", "requires"
          process.send(statement.predicate, statement.object)
        else
          raise "Unknown dependency #{statement.predicate}"
        end
      end

      candidate_root_processes = processes.values.select(&:root?)

      if candidate_root_processes.count == 1
        candidate_root_processes.first
      else
        IDEF0::Process.new("__root__", candidate_root_processes)
      end

    end

    def initialize(name, children = [])
      @name = name
      @parent = nil
      @children = ArraySet.new
      @dependencies = Hash.new { |hash, side| hash[side] = ArraySet.new }
      children.each { |child| add_child(child) }
    end

    def root?
      @parent.nil?
    end

    def leaf?
      @children.empty?
    end

    def parent=(other)
      raise "Already a child" unless root?
      @parent = other
    end

    def add_child(other)
      raise "Cyclic composition" if other.ancestor_of?(self)
      @children.add(other)
      other.parent = self
    end

    { :receives => :left_side, :produces => :right_side, :respects => :top_side, :requires => :bottom_side }.each do |type, side|
      define_method(type) do |name|
        @dependencies[side].add(name)
      end
    end

    def each_dependency
      @dependencies.each do |side, names|
        names.each do |name|
          yield(side, name)
        end
      end
    end

    def ancestor_of?(other)
      parent_of?(other) || @children.any? { |child| child.ancestor_of?(other) }
    end

    def parent_of?(other)
      @children.include?(other)
    end

    def decomposable?
      !@children.empty?
    end

    def decompose
      focus unless decomposable?
      diagram = IDEF0.diagram(@name) do |diagram|
        render(diagram)
        @children.each do |child|
          child.render(diagram.box(child.name))
        end
      end
    end

    def focus
      parent = @parent || self
      diagram = IDEF0.diagram(parent.name) do |diagram|
        parent.render(diagram)
        render(diagram.box(@name))
      end
    end

    def schematic
      diagram = IDEF0.diagram(@name) do |diagram|
        each_leaf do |leaf|
          leaf.render(diagram.box(leaf.name))
        end
      end
    end

    def render(box)
      each_dependency do |side, name|
        box.send(side).expects(name)
      end
    end

    def each_leaf(&block)
      yield(self) and return if leaf?
      @children.each do |child|
        child.each_leaf(&block)
      end
    end

  end

end


