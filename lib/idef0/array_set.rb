require 'forwardable'

module IDEF0

  class ArraySet

    extend Forwardable

    def initialize(items = [])
      boom! unless items.is_a?(Array)
      @items = items
    end

    def_delegators :@items, :index, :[], :count, :each, :include?, :find, :inject, :each_with_index, :map, :any?

    def union(other)
      self.class.new(@items.dup).union!(other)
    end
    def_delegator :self, :union, :+

    def union!(other)
      other.each { |item| @items.push(item) }
      self
    end

    def get(predicate, &block)
      unless item = find(&predicate)
        if block_given?
          item = yield
          add(item)
        end
      end
      item
    end

    def add(item)
      @items.push(item) unless include?(item)
      self
    end
    def_delegator :self, :add, :<<

    def delete(item)
      self.class.new(@items.dup).delete!(item)
    end

    def delete!(item)
      @items.delete(item)
      self
    end

    def reduce(initial = nil, &block)
      @items.reduce(initial, &block)
    end

    def select(&block)
      self.class.new(@items.select(&block))
    end

    def sort_by(&block)
      self.class.new(@items.sort_by(&block))
    end

    def group_by(&block)
      @items.reduce(Hash.new { |h, k| h[k] = self.class.new }) do |groups, item|
        groups[yield(item)].add(item)
        groups
      end
    end

    def partition(&block)
      @items.partition(&block).map { |items| self.class.new(items) }
    end

    def sequence_by(&block)
      sort_by(&block).tap do |set|
        set.each_with_index { |item, index| item.sequence = index }
      end
    end

  end

end
