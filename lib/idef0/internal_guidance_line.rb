require_relative 'line'

module IDEF0

  class InternalGuidanceLine < Line

    def attach
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.top_side.attach(self)
      self
    end

  end

end
