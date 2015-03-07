require 'yajl' unless defined?(Yajl)
require 'json'

module Icapnd
  #http://apple.co/17IAp6G
  #http://apple.co/1EKPH7P
  class Notification
    PAYLOAD_MAX_PRIOR_IOS8 = 256
    PAYLOAD_MAX = 2 * 1024

    attr_accessor :device_token, :alert, :badge, :sound, :custom
    attr_accessor :identifier, :expiration, :priority

    attr_reader :payload
    class PayloadTooLarge < StandardError;end
    class NoDeviceToken < StandardError;end

    def initialize( before_ios8 = true )
      @max_payload_size = before_ios8 == true ? PAYLOAD_MAX_PRIOR_IOS8 : PAYLOAD_MAX
      @payload = {aps:{}}

      @data = {}
      @identifier = nil #Arbitrary, opaque value is used for reporting errors on server
      @expiration = nil #UTC epoch in seconds
      @priority   = nil #5:Push message is sent at a time that conserves power on the device
                        #10:Push message is sent immediately
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
      value = value.slice(0, 120) << "..." if value.is_a?(String) and value.length > 150
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
    #identifier, :expiration, :priority
    #http://apple.co/1EKPH7P
    #--------+----------+-------+
    #ItemID  | ItemName | Length|
    #--------+----------+-------+
    #   1    |  Token   |   32  | 
    #--------+----------+-------+
    #   2    |  Payload | <=2K  | 
    #--------+----------+-------+
    #   3    |Identifier|   4   | 
    #--------+----------+-------+
    #   4    |Expiration|   4   | 
    #--------+----------+-------+
    #   5    |  Priority|   1   | 
    #--------+----------+-------+

    #Ruby Array's pack method
    #---------------------------------------------------------------
    # c   : 8-bit signed (signed char)
    # n   : 16-bit unsigned, network (big-endian) byte order
    # N   : 32-bit unsigned, network (big-endian) byte order
    # H   : hex string (high nibble first)
    # a   : arbitrary binary string (null padded, count is width)
    # *   : All remaining characters will beconverted
    #[ItemID, Number_of_Bytes, Idnentifier]

    def identifier=(value)
      value = value.to_i
      value = rand(65535) if value == 0
      @identifier = value
      @data.merge!({identifier: @identifier})
      # @identifier = [3, 4, value].pack('cnN')
    end

    def expiration=(value)
      @expiration = value.to_i
      @data.merge!({expiration: @expiration})
      # @expiration = [4, 4, value].pack('cnN')
    end

    def priority=(value)
      value = value.to_i
      value = 10 unless [5, 10].include?(value)
      @priority = value
      @data.merge!({priority: @priority})
      # @priority = [5, 1, value].pack('cnc')
    end

    def encode_payload
        raise NoDeviceToken.new("No device token") unless device_token
        @data[:device_token] = device_token
        if valid?
          @data.merge!({payload: @payload})
          Yajl::Encoder.encode( @data )
        end
    end

    def valid?
      Yajl::Encoder.encode(@payload).bytesize < @max_payload_size
      #@payload.to_json.bytesize < @max_payload_size
    end

    def push
      raise 'No Redis client' if Config.redis.nil?
      socket = Config.redis.rpush "apnmachine.queue", encode_payload
      # redis = Redis.new({host:'127.0.0.1', port:6379, :driver => :hiredis})
      # socket = redis.rpush "apnmachine.queue", encode_payload
    end

    def self.to_bytes(encoded_payload)
      data = nil
      hash_data = Yajl::Parser.parse( encoded_payload )

      payload = hash_data.delete('payload') 
      encoded = Yajl::Encoder.encode( payload )
      token = hash_data.delete('device_token')

      if hash_data.empty?
        token_bin = [token].pack('H*')
        data = [0, 0, 32, token_bin, 0, encoded.bytesize, encoded].pack("ccca*cca*")
      else identifier = hash_data.delete('identifier')
        expiration = hash_data.delete('expiration')
        priority = hash_data.delete('priority')

        identifier ||= rand(65535) 
        expiration ||= 3600
        priority ||= 10

        frame = [ 
                [1, 32, token].pack('cnH64'),                   #token
                [2, encoded.bytes.count, encoded].pack('cna*'), #payload
                [3, 4, identifier].pack('cnN'),                 #identifier
                [4, 4, expiration].pack('cnN'),                 #expiration
                [5, 1, priority].pack('cnc')                    #priority
          ].compact.join
        data = [2, frame.bytes.count, frame].pack('cNa*')
      end
      data
    end
  end

end
