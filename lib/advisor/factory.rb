module Advisor
  class Factory
    def initialize(advice_klass, applier_name)
      @advice_klass = advice_klass
      @applier_name = applier_name
    end

    def build
      Module.new do
        define_method(applier_name) do |*methods, **args|
          prepend advisor_module(methods, args)
        end
      end
    end

    protected

    attr_reader :advice_klass, :applier_name

    private

    def advisor_module(methods, args)
      Module.new do
        methods.each do |method_name|
          define_method(method_name) do |*call_args, &blk|
            advice = advice_klass.new(self, method_name, call_args, **args)
            advice.apply { super(*call_args, &blk) }
          end
        end
      end
    end
  end
end
