require 'logger'

module Advisor
  Loggable = Factory.new(Advices::CallLogger).build
end
