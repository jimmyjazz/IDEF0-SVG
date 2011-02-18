module IDEF0

  class UnsatisfiedOutputLine < ExternalOutputLine

    def self.make_line(target, source)
      source.right_side.each_unattached_anchor do |anchor|
        target.right_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    alias_method :svg_line, :svg_dashed_line

  end

end
