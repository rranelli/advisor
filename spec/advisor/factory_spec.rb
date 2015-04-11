describe Advisor::Factory do
  subject(:factory) { described_class.new(advice_klass, applier) }
  let(:applier) { 'apply_advice_to' }

  let(:advice_klass) do
    Struct.new(:obj, :method, :call_args, :args) do
      define_method(:call) { 'overridden!' }
    end
  end
  let(:advice_instance) do
    advice_klass.new(advised_instance, :apply_advice_to, [], [])
  end

  let(:advised_klass) do
    advisor = build

    Struct.new(:advised_method) do
      extend advisor

      apply_advice_to :advised_method
    end
  end
  let!(:advised_instance) { advised_klass.new(33) }

  before do
    allow(advised_klass).to receive(:new)
      .and_return(advised_instance)

    allow(advice_klass).to receive(:new)
      .and_return(advice_instance)
  end

  describe '#build' do
    subject(:build) { factory.build }

    it { is_expected.to be_kind_of(Module) }

    describe "when applying the advice to a class' methods" do
      subject(:invoke_advised_method) { advised_instance.advised_method }

      it do
        expect(advice_klass).to receive(:new)
          .with(advised_instance, :advised_method, [], {})

        invoke_advised_method
      end

      it do
        expect(advice_instance).to receive(:call)

        invoke_advised_method
      end
      it { is_expected.to eq('overridden!') }
    end
  end
end
