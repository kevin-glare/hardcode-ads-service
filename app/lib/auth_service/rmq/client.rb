# frozen_string_literal: true

require 'securerandom'
require 'json'
require_relative 'api'

module AuthService
  module Rmq
    class Client
      include Api
      extend Dry::Initializer[undefined: false]

      option :queue, default: proc { create_queue }
      option :reply_queue, default: proc { create_reply_queue }
      option :lock, default: proc { Mutex.new }
      option :condition, default: proc { ConditionVariable.new }

      attr_reader :response

      def self.fetch
        Thread.current['auth_service.rpc_client'] ||= new.start
      end

      def start
        @reply_queue.subscribe do |_delivery_info, properties, payload|
          if properties[:correlation_id] == @correlation_id
            self.response = JSON(payload)['user_id']

            @lock.synchronize { @condition.signal }
          end
        end

        self
      end

      private

      attr_writer :correlation_id, :response

      def create_queue
        channel = RabbitMq.channel
        channel.queue('authorization', durable: true)
      end

      def create_reply_queue
        channel = RabbitMq.channel
        channel.queue('amq.rabbitmq.reply-to', durable: true)
      end

      def publish(payload, opts = {})
        self.correlation_id = SecureRandom.uuid

        @lock.synchronize do
          @queue.publish(
            payload,
            opts.merge(
              app_id: 'ads',
              correlation_id: @correlation_id,
              reply_to: @reply_queue.name
            )
          )

          @condition.wait(@lock)
        end
      end
    end
  end
end
