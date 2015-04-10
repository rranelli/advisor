require 'logger'

module Advisor
  describe Factory do
    subject(:loggable) do
      Advices::CallLogger.default_logger = default_logger

      Class.new do
        extend Loggable
        log_calls_to :inc

        def inc(number)
          number + 1
        end

        def foo(*)
        end
      end
    end

    let(:loggable_instance) { loggable.new }
    let(:default_logger) { instance_double(Logger, info: nil, warn: nil) }
    let(:call_logger) do
      Advices::CallLogger.new(
        loggable_instance, :inc, [1], logger: default_logger
      )
    end

    before do
      allow(Advices::CallLogger).to receive(:new)
        .and_return(call_logger)
    end

    it 'instantiates a call logger when calling the advised method' do
      expect(Advices::CallLogger)
        .to receive(:new)
        .with(loggable_instance, :inc, [1], {})
        .and_call_original

      loggable_instance.inc(1)
    end

    it 'uses the call_logger to log the method call' do
      expect(call_logger)
        .to receive(:apply)
        .and_call_original

      loggable_instance.inc(1)
    end

    it 'does not change the return value' do
      expect(loggable_instance.inc(1)).to eq(2)
    end

    it 'does not log when calling a non-advised method' do
      expect(Advices::CallLogger).to_not receive(:new)

      loggable_instance.foo
    end

    describe '#log_calls_to' do
      subject(:log_calls_to) { loggable.send(:log_calls_to, :foo, :bar) }

      it 'prepends an anonymous module in the ancestor chain' do
        expect(loggable).to receive(:prepend)
          .and_call_original

        expect { log_calls_to }.to change { loggable.ancestors.count }.by(1)
      end

      context 'when redefining an advised method' do
        let(:child_class) do
          Class.new(loggable) do
            def inc(number)
              number + 2
            end
          end
        end

        let(:child_class_instance) { child_class.new }

        it 'the advice is overridden' do
          log_calls_to

          expect(Advices::CallLogger).not_to receive(:new)
          expect(child_class_instance.inc(1)).to eq(3)
        end
      end
    end
  end
end
