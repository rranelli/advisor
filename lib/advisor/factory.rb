module Advisor
  class Factory
    def initialize(advice_klass, applier_name)
      @advice_klass = advice_klass
      @applier_name = applier_name
    end

    def build
      name = applier_name
      advice_applier = method(:advisor_module)

      Module.new do
        define_method(name) do |*methods, **args|
          prepend advice_applier.call(methods, args)
        end
      end
    end

    protected

    attr_reader :advice_klass, :applier_name

    private

    def advisor_module(methods, args)
      advice_klazz = advice_klass

      Module.new do
        methods.each do |method_name|
          define_method(method_name) do |*call_args, &blk|
            advice = advice_klazz.new(self, method_name, call_args, **args)
            advice.call { super(*call_args, &blk) }
          end
        end
      end
    end
  end
end
