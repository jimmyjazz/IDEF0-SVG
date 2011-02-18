require_relative 'array_set'
require_relative 'diagram'

module IDEF0

  class Process

    attr_reader :name

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
          diagram.box(child.name) do |box|
            child.render(box)
          end
        end
      end
    end

    def focus_diagram
      raise "TODO: Not implemented yet"
    end

    def render(box)
      each_dependency do |type, name|
        box.send(type, name)
      end
    end

  end

end


