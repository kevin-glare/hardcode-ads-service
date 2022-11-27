# frozen_string_literal: true

require 'json'

channel = RabbitMq.consumer_channel
exchange = channel.default_exchange
queue = channel.queue('ads', durable: true)

queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
  payload = JSON(payload)
  puts payload if Application.environment == :development

  lat, lon = payload['coordinates']

  Ads::UpdateService.call(payload['id'], { lat: lat, lon: lon })

  exchange.publish(
    '',
    routing_key: properties.reply_to,
    correlation_id: properties.correlation_id
  )

  channel.ack(delivery_info.delivery_tag)
end