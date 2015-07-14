require 'logger'

module Advisor
  module Advices
    class CallLogger
      class << self
        attr_accessor :default_logger
        attr_accessor :catch_exception
      end
      self.default_logger = Logger.new(STDOUT)
      self.catch_exception = false

      def initialize(object, method, call_args, **opts)
        @object = object
        @method = method
        @call_args = call_args
        @logger = opts[:logger] || CallLogger.default_logger
        @tag_proc = opts[:with] || ->{}
      end

      attr_reader :object, :method, :call_args, :logger, :tag_proc

      def self.applier_method
        :log_calls_to
      end

      def call
        logger.info(success_message)
        yield
      rescue exception_class => e
        logger.warn(failure_message(e))
        raise
      end

      private

      def success_message
        call_message('Called: ')
      end

      def failure_message(ex)
        backtrace = ["\n", ex.to_s] + ex.backtrace
        call_message('Failed: ', backtrace.join("\n"))
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
