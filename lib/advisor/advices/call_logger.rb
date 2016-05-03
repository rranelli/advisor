require 'logger'

module Advisor
  module Advices
    class CallLogger
      class << self
        attr_accessor :backtrace_cleaner
        attr_accessor :default_logger
        attr_accessor :catch_exception
      end
      self.default_logger = Logger.new(STDOUT)

      def initialize(object, method, call_args, **opts)
        @object = object
        @method = method
        @call_args = call_args

        @cleaner = opts[:backtrace_cleaner] || CallLogger.backtrace_cleaner
        @logger = opts[:logger] || CallLogger.default_logger
        @tag_proc = opts[:with] || -> {}
        @log_result = opts[:result] || false
      end

      attr_reader(
        :object, :method, :call_args, :logger, :tag_proc, :log_result, :cleaner
      )

      def self.applier_method
        :log_calls_to
      end

      def call
        logger.info(success_message)
        yield.tap(&result_message)
      rescue exception_class => e
        logger.error(failure_message(e))
        raise
      end

      private

      def success_message
        call_message('Called: ')
      end

      def failure_message(ex)
        backtrace = ["\n", ex.to_s] + ex.backtrace
        backtrace = cleaner.clean(backtrace) if cleaner
        call_message('Failed: ', backtrace.join("\n"))
      end

      def result_message
        lambda do |result|
          return unless log_result

          logger.info(
            call_message('Result: ', " => #{result.class}: #{result.inspect}")
          )
        end
      end

      def call_message(prefix, suffix = '')
        "#{time}#{thread}#{id}#{custom_tag}#{prefix}\
#{klass}##{method}(#{arguments})\
#{suffix}"
      end

      def thread
        "[Thread=#{Thread.current.object_id}]"
      end

      def time
        "[Time=#{Time.now}]"
      end

      def custom_tag
        object.instance_exec(&tag_proc)
      end

      def klass
        object.class
      end

      def arguments
        call_args.map(&:inspect).join(', ')
      end

      def id
        "[id=#{object.id}]" if object.respond_to?(:id)
      end

      def exception_class
        CallLogger.catch_exception ? Exception : StandardError
      end
    end
  end
end
