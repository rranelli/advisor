require 'logger'

module Advisor
  Loggable = Factory.new(Advices::CallLogger).build
  Measurable = Factory.new(Advices::Metriks).build
end
