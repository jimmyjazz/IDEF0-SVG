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
          process.add_dependency(statement.predicate, statement.object)
        else
          raise "Unknown predicate #{statement.predicate.inspect}"
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
      @dependencies = Hash.new { |hash, type| hash[type] = ArraySet.new }
      children.each { |child| add_child(child) }
    end

    def root?
      @parent.nil?
    end

    def parent=(other)
      raise "Already a child" unless root?
      @parent = other
    end

    def add_child(child)
      raise "Cyclic composition" if child.ancestor_of?(self)
      @children.add(child)
      child.parent = self
    end

    def add_dependency(type, name)
      @dependencies[type].add(name)
    end

    def each_dependency
      @dependencies.each do |type, names|
        names.each do |name|
          yield(type, name)
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

    def decomposition_diagram
      focus_diagram unless decomposable?
      diagram = IDEF0.diagram(@name) do |diagram|
        render(diagram)
        @children.each do |child|
          child.render(diagram.box(child.name))
        end
      end
    end

    def focus_diagram
      parent = @parent || self
      diagram = IDEF0.diagram(parent.name) do |diagram|
        parent.render(diagram)
        render(diagram.box(@name))
      end
    end

    def render(box)
      each_dependency do |type, name|
        box.send(type, name)
      end
    end

  end

end


