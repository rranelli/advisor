require 'ostruct'

module Advisor
  module Advices
    describe Metriks do
      subject(:advice) do
        described_class.new(
          object,
          method,
          args,
          logger: logger,
          with: instruments
        )
      end

      let(:object) { OpenStruct.new(when: '2015-12-18') }
      let(:method) { 'the_force_awakens' }
      let(:args) { ['vai ser zika', 'demais'] }
      let(:logger) { instance_double(Logger, warn: nil) }

      let(:block) { -> { 42 } }

      context 'when no instruments are specified' do
        let(:instruments) { [] }

        it { expect { call }.to raise_error }
      end

      describe '.applier_method' do
        subject { Metriks.applier_method }
        it { is_expected.to eq(:measure) }
      end

      describe '#call' do
        subject(:call) { advice.call(&block) }

        let(:instruments) { %i(counter result_meter call_meter gauge) }

        shared_examples_for 'instruments && measuring' do
          it('returns the block call value') { is_expected.to eq(42) }

          it 'instantiates a counter with the right metric name' do
            expect(::Metriks).to receive(:counter)
              .with('OpenStruct#the_force_awakens_counter')
              .and_call_original

            subject
          end

          it 'instantiates gauge with the right metric name' do
            expect(::Metriks).to receive(:gauge)
              .with('OpenStruct#the_force_awakens_gauge')
              .and_call_original

            subject
          end

          it 'instantiates a method call and a meter with the right metric names' do
            expect(::Metriks).to receive(:meter)
              .with('OpenStruct#the_force_awakens_call_meter')
              .and_call_original

            expect(::Metriks).to receive(:meter)
              .with('OpenStruct#the_force_awakens_result_meter')
              .and_call_original

            subject
          end

          let(:result_meter) { instance_double(::Metriks::Meter) }
          let(:call_meter) { instance_double(::Metriks::Meter) }

          it 'increments a method call counter' do
            expect(::Metriks).to receive_message_chain(
              :counter, :increment
            )

            subject
          end

          it 'marks a method call and a block result value meter' do
            expect(::Metriks).to receive(:meter)
              .with('OpenStruct#the_force_awakens_result_meter')
              .and_return(result_meter)

            expect(result_meter).to receive(:mark)
              .with(42)

            expect(::Metriks).to receive(:meter)
              .with('OpenStruct#the_force_awakens_call_meter')
              .and_return(call_meter)

            expect(call_meter).to receive(:mark)

            subject
          end

          it 'sets the block result value gauge' do
            expect(::Metriks).to receive_message_chain(
              :gauge, :set
            ).with(42)

            subject
          end

          context 'when the block return value is not numeric' do
            let(:block) { -> { :war_in_the_stars } }

            it 'does not instantiate a block return value meter' do
              expect(::Metriks).to receive(:meter)
                .with('OpenStruct#the_force_awakens_call_meter')
                .and_return(call_meter)
              expect(call_meter).to receive(:mark)

              expect(::Metriks).not_to receive(:meter)
                .with('OpenStruct#the_force_awakens_result_meter')

              subject
            end

            it 'does not instantiate a block return value gauge' do
              expect(::Metriks).not_to receive(:gauge)

              subject
            end

            it 'instantiates a method call meter and marks it' do
              expect(::Metriks).to receive(:counter)
                .and_call_original

              subject
            end
          end
        end

        it_behaves_like 'instruments && measuring'

        context 'when using a timer' do
          let(:instruments) { %i(counter result_meter call_meter gauge timer) }

          let(:timer) { instance_double(::Metriks::Timer) }

          before do
            allow(::Metriks).to receive(:timer)
              .and_return(timer)

            allow(timer).to receive(:time)
            allow(timer).to receive(:stop)
          end

          it_behaves_like 'instruments && measuring'

          it 'finds the right timer metric' do
            expect(::Metriks).to receive(:timer)
              .with('OpenStruct#the_force_awakens_timer')

            call
          end

          it 'times the method call' do
            expect(timer).to receive(:time)
            expect(timer).to receive(:stop)

            call
          end
        end

        context 'when there are duplicate instruments' do
          let(:instruments) do
            %i(counter result_meter call_meter counter gauge gauge)
          end

          it_behaves_like 'instruments && measuring'
        end
      end
    end
  end
end
