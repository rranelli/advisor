require 'logger'
require 'metriks'

module Advisor
  module Advices
    class Metriks
      class << self
        attr_accessor :default_logger
      end
      self.default_logger = Logger.new(STDOUT)

      def initialize(object, method, _call_args, **opts)
        @object = object
        @method = method

        @instruments = Array(opts.fetch(:with)).uniq
        @logger = opts[:logger] || Metriks.default_logger

        fail 'No instruments defined' if instruments.empty?
        fail 'Unknown Instrument' unless instruments.all?(&known_instrument?)
      end

      attr_reader :object, :method, :logger, :instruments

      INSTRUMENTS = [
        :counter, :timer, :gauge, :call_meter, :result_meter
      ]

      def self.applier_method
        :measure
      end

      def call
        result = timed? ? timer.time { yield } : yield
        result.tap { instruments.each(&measure(result)) }
      rescue => e
        logger.warn(e)
        raise
      end

      private

      def measure(result)
        # How I wish I had currying...
        lambda do |instrument|
          is_numeric = result.is_a?(Fixnum)

          case instrument
          when :counter      then counter.increment
          when :call_meter   then call_meter.mark
          when :result_meter then is_numeric && result_meter.mark(result)
          when :gauge        then is_numeric && gauge.set(result)
          end
        end
      end

      def timed?
        instruments.include?(:timer)
      end

      def metric_prefix
        "#{object.class}##{method}"
      end

      def timer
        ::Metriks.timer("#{metric_prefix}_#{__callee__}")
      end

      def counter
        ::Metriks.counter("#{metric_prefix}_#{__callee__}")
      end

      def gauge
        ::Metriks.gauge("#{metric_prefix}_#{__callee__}")
      end

      def call_meter
        ::Metriks.meter("#{metric_prefix}_#{__callee__}")
      end

      def result_meter
        ::Metriks.meter("#{metric_prefix}_#{__callee__}")
      end

      def known_instrument?
        -> (instrument) { INSTRUMENTS.include?(instrument) }
      end
    end
  end
end
