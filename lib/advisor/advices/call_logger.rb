require 'logger'

module Advisor
  module Advices
    class CallLogger
      def initialize(object, method, call_args, **opts)
        @object = object
        @method = method
        @call_args = call_args
        @logger = opts[:logger] || Logger.new(STDOUT)
      end

      attr_reader :object, :method, :call_args, :logger

      def apply
        logger.info(success_message)
        yield
      rescue => e
        logger.error(failure_message(e))
        raise
      end

      private

      def success_message
        call_message('Called: ')
      end

      def failure_message(ex)
        call_message('Failed: ', "\n#{ex}")
      end

      def call_message(prefix, suffix = '')
        "#{time}#{thread}#{id}#{prefix}\
#{klass}##{method}(#{arguments})\
#{suffix}"
      end

      def thread
        "[Thread=#{Thread.current.object_id}]"
      end

      def time
        "[Time=#{Time.now}]"
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
    end
  end
end
