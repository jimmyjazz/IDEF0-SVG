module IDEF0
  class Noun
    PATTERN = "[^a-z; ][^; ]*?(?: [^a-z; ][^; ]*?)*"

    def self.parse(text)
      normalised_text = text.to_s.squish.gsub(/(^|\s)[a-z]/) { |l| l.upcase }
      raise(ArgumentError, "Invalid noun: #{text.inspect}") unless /^#{PATTERN}$/ === normalised_text
      normalised_text
    end
  end
end
