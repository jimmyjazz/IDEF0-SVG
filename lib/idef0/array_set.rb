require 'forwardable'

module IDEF0

  class ArraySet

    extend Forwardable

    def initialize(items = [])
      boom! unless items.is_a?(Array)
      @items = items
    end

    def_delegators :@items, :index, :[], :count, :each, :include?, :find, :inject, :each_with_index, :map, :any?, :empty?

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
      dup.delete!(item)
    end

    def delete!(item)
      @items.delete(item)
      self
    end

    def insert(index, object)
      dup.insert!(index, object)
    end

    def insert!(index, object)
      @items.delete(object)
      @items.insert(index, object)
      self
    end

    def reduce(initial = nil, &block)
      @items.reduce(initial, &block)
    end

    def select(&block)
      self.class.new(@items.select(&block))
    end

    def reject(&block)
      self.class.new(@items.reject(&block))
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

    def sequence!
      @items.each_with_index { |item, index| item.sequence = index }
      self
    end

    def permutation
      @items.permutation { |items| yield(self.class.new(items)) }
      self
    end

    def dup
      self.class.new(@items.dup)
    end

  end

end
