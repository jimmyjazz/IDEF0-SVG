require_relative 'line'

module IDEF0

  class InternalMechanismLine < Line

    def attach
      @source_anchor = source.right_side.attach(self)
      @target_anchor = target.bottom_side.attach(self)
      self
    end

    def x_vertical
      x1 + clearance_from(@source.right_side)
    end

    def bottom_edge
      y_horizontal
    end

  end

end
