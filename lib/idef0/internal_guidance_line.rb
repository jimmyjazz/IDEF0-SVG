require_relative 'line'

module IDEF0

  class InternalGuidanceLine < Line

    def connect
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.top_side.attach(self)
    end

  end

end
