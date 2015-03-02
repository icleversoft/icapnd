require 'yajl' unless defined?(Yajl)

module Icapnd
  #http://apple.co/17IAp6G
  class Notification
    PAYLOAD_MAX_PRIOR_IOS8 = 256
    PAYLOAD_MAX = 2 * 1024

    attr_accessor :device_token, :alert, :badge, :sound, :custom
    attr_reader :payload
    class PayloadTooLarge < StandardError;end
    class NoDeviceToken < StandardError;end

    def initialize( before_ios8 = true )
      @max_payload_size = before_ios8 == true ? PAYLOAD_MAX_PRIOR_IOS8 : PAYLOAD_MAX
      @payload = {aps:{}}
    end

    def add_to_payload( hash )
      @payload.merge!( hash ) if hash.is_a?(Hash)
      @payload
    end

    def badge=(value)
      @payload[:aps][:badge] = value.to_i
      @payload
    end

    def alert=(value)
      @payload[:aps][:alert] = value
      @payload
    end

    def sound=(value)
      @payload[:aps][:sound] = value
      @payload
    end

    def force_silent
      @silent = true
      @payload[:aps]['content-available'] = 1
    end

    def encode_payload
      raise NoDeviceToken.new("No device token") unless device_token
      @payload[:device_token] = device_token
      j = Yajl::Encoder.encode( @payload )
      raise PayloadTooLarge.new("The payload length: #{j.length} is larger than allowed: #{@max_payload_size}") if j.size > @max_payload_size
      Yajl::Encoder.encode(@payload)
    end

    def push
      raise 'No Redis client' if Config.redis.nil?
      socket = Config.redis.rpush "apnmachine.queue", encode_payload
    end

    def self.to_bytes(encoded_payload)
      notif_hash = Yajl::Parser.parse(encoded_payload)

      device_token = notif_hash.delete('device_token')
      bin_token = [device_token].pack('H*')
      raise NoDeviceToken.new("No device token") unless device_token

      j = Yajl::Encoder.encode(notif_hash)
      raise PayloadTooLarge.new("The payload length: #{j.length} is larger than allowed: #{@max_payload_size}") if j.size > @max_payload_size

      Config.logger.debug "TOKEN:#{device_token} | ALERT:#{notif_hash.inspect}"

      [0, 0, 32, bin_token, 0, j.bytesize, j].pack("ccca*cca*")
    end

  end

end
