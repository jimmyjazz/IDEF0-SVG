require_relative 'line'

module IDEF0
  class ExternalLine < Line
    def anchor_precedence(side)
      []
    end
  end
end
