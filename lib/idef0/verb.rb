module IDEF0

  class Verb

    PATTERN = "[a-z][^ ]*?(?: [a-z][^ ]*?)*"

    def self.parse(text)
      normalised_text = text.to_s.squish.downcase
      raise(ArgumentError, "Invalid verb: #{text.inspect}") unless /^#{PATTERN}$/ === normalised_text
      normalised_text
    end

  end

end
