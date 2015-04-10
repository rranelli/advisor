module Advisor
  Loggable = Factory.new(Advices::CallLogger, :log_calls_to)
end
