module IDEF0

  class UnsatisfiedInputLine < ExternalInputLine

    def self.make_line(source, target)
      target.left_side.each_unattached_anchor do |anchor|
        source.left_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

  end

end
