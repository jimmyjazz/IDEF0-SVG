module IDEF0
  class UnsatisfiedGuidanceLine < ExternalGuidanceLine
    def self.make_line(source, target)
      target.top_side.each_unattached_anchor do |anchor|
        source.top_side.expects(anchor.name)
        yield(new(source, target, anchor.name))
      end
    end

    alias_method :svg_line, :svg_dashed_line
  end
end
