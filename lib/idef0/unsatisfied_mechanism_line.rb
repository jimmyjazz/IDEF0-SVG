module IDEF0

  class UnsatisfiedMechanismLine < ExternalMechanismLine

    def self.make_line(source, target)
      target.bottom_side.each_unattached_anchor do |anchor|
        source.bottom_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    alias_method :svg_line, :svg_dashed_line

  end

end
