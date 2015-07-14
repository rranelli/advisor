require 'ostruct'

module Advisor
  module Advices
    describe CallLogger do
      subject(:advice) do
        described_class.new(object, method, args, logger: logger, with: tag)
      end

      let(:object) { OpenStruct.new(id: 42, x: 'y') }
      let(:method) { 'the_meaning_of_life' }
      let(:args) { ['the universe', 'and everything'] }
      let(:logger) { instance_double(Logger) }
      let(:tag) { -> { "[x=#{x}]" } }

      let(:block) { -> { :bla } }

      describe '#call' do
        subject(:call) { advice.call(&block) }

        let(:log_message) do
          "[Time=#{Time.now}][Thread=#{Thread.current.object_id}][id=42][x=y]\
Called: OpenStruct#the_meaning_of_life(\"the universe\", \"and everything\")"
        end

        before do
          allow(Time).to receive(:now).and_return(Time.now)
          allow(logger).to receive(:info)
        end

        it { is_expected.to eq(:bla) }

        it do
          expect(logger).to receive(:info).with(log_message)

          call
        end

        context 'when yielding the block raises an error' do
          let(:block) { -> () { fail 'deu ruim!' } }

          let(:log_message) do
            /\[Time=#{Time.now}\]\[Thread=#{Thread.current.object_id}\]\
\[id=42\]\[x=y\]Failed: OpenStruct#the_meaning_of_life\(\"the universe\", \"and\
 everything\"\).*/
          end

          let(:error_message) { /deu ruim!/ }

          let(:catch_exception) { false }

          before do
            allow(logger).to receive(:warn)
            allow(CallLogger).to receive(:catch_exception)
              .and_return(catch_exception)
          end

          it { expect { call }.to raise_error(StandardError, 'deu ruim!') }

          it do
            expect(logger).to receive(:warn).with(log_message)
            expect { call }.to raise_error
          end

          it do
            expect(logger).to receive(:warn).with(error_message)
            expect { call }.to raise_error
          end

          context 'when the error is not a StandardError' do
            let(:block) { -> { fail Exception, 'deu muito ruim!' } }

            let(:error_message) { /deu muito ruim!/ }

            it do
              expect(logger).not_to receive(:warn).with(log_message)
              expect { call }.to raise_error(Exception, 'deu muito ruim!')
            end

            context 'when catching exceptions' do
              let(:catch_exception) { true }

              it do
                expect(logger).to receive(:warn).with(log_message)
                expect { call }.to raise_error(Exception, 'deu muito ruim!')
              end

              it do
                expect(logger).to receive(:warn).with(error_message)
                expect { call }.to raise_error(Exception, 'deu muito ruim!')
              end
            end
          end
        end

        context 'when no custom tag is provided' do
          let(:tag) {}
          let(:log_without_custom_tag) { log_message.gsub("[x=y]", "") }

          it do
            expect(logger).to receive(:info).with(log_without_custom_tag)

            call
          end
        end
      end
    end
  end
end
