require 'forwardable'

module IDEF0

  class ArraySet

    extend Forwardable

    def initialize(items = [])
      @items = items
    end

    def_delegators :@items, :index, :[], :count, :each, :include?, :find, :inject, :each_with_index, :map, :any?, :group_by

    def union(other)
      self.class.new(@items.dup).union!(other)
    end
    def_delegator :self, :union, :+

    def union!(other)
      other.each { |item| @items << item }
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
      @items << item unless include?(item)
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

    def before(pattern)
      self.class.new(@items.take_while { |item| item != pattern })
    end

    def after(pattern)
      self.class.new(@items.drop_while { |item| item != pattern }[1..-1])
    end

    def select(&block)
      self.class.new(@items.select(&block))
    end

    def sort_by(&block)
      self.class.new(@items.sort_by(&block))
    end

    def partition(&block)
      @items.partition(&block).map { |items| self.class.new(items) }
    end

  end

end
