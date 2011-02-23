require_relative 'statement'
require_relative 'process'

class Object

  def inspect
    "<#{self.class.name}:#{object_id}>"
  end

end

module IDEF0

  module CLI

    def self.process(io, args)
      statements = IDEF0::Statement.parse(io)
      process = IDEF0::Process.parse(statements)
      process_name = args[0] || process.name
      process = process.find(process_name)
      if process.nil?
        $stderr.puts "Error: process not found #{process_name.inspect}"
        exit
      end
      process
    end

  end

end

