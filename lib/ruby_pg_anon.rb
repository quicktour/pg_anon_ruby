class RubyPgAnon
  def self.call(command)
    Command::Initilizer.new(command).call
  end
end

require 'command/initializer'