class RubyPgAnon
  def self.call(command)
    Command::Initializer.new(command).call
  end
end

require 'command/initializer'