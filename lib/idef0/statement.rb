require_relative 'noun'
require_relative 'verb'
require_relative 'string_squishing'
require_relative 'string_comment_detection'

module IDEF0
  class Statement
    FORMAT = /^(#{Noun::PATTERN}) (#{Verb::PATTERN}) (#{Noun::PATTERN})$/

    attr_reader :subject, :predicate, :object

    def self.assemble(subject, predicate, object)
      new(Noun.parse(subject), Verb.parse(predicate), Noun.parse(object))
    end

    def self.parse(text)
      text.each_line
        .map(&:squish)
        .compact
        .reject(&:comment?)
        .map { |line|
          raise line.inspect unless line =~ FORMAT
          assemble($1, $2, $3)
        }
    end

    def initialize(subject, predicate, object)
      @subject = subject
      @predicate = predicate
      @object = object
    end

    def to_s
      [@subject, @predicate, @object].join(" ")
    end

    def eql?(other)
      @subject == other.subject &&
        @predicate == other.predicate &&
        @object == other.object
    end
    alias_method :==, :eql?

    def hash
      @hash ||= @subject.hash ^ @predicate.hash ^ @object.hash
    end
  end
end
