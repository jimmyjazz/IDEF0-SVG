require_relative 'array_set'
require_relative 'diagram'

module IDEF0

  class Process

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

    def each_dependency(&block)
      @dependencies.each(&block)
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
        each_dependency do |type, name|

        end

      end

    end


      #   statements.each do |statement|
      #     case statement.predicate
      #     when "is composed of"
      #       diagram.box(statement.object)
      #     when "receives", "produces", "respects", "requires"
      #       if statement.subject == diagram.name
      #         diagram.send(statement.predicate, statement.object)
      #       else
      #         diagram.box(statement.subject) do |box|
      #           box.send(statement.predicate, statement.object)
      #         end
      #       end
      #     end
      #   end
      # end

    def focus_diagram
      raise "TODO: Not implemented yet"
    end

  end

end
