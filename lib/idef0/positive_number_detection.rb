module IDEF0

  module PositiveNumberDetection

    def positive?
      self > 0
    end

  end

  Numeric.send(:include, PositiveNumberDetection)

end
