module IDEF0

  module StringSquishing

    def squish
      x = self.gsub(/\s+/, ' ').strip
      x unless x.empty?
    end

  end

  String.send(:include, StringSquishing)

end
