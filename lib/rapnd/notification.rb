module Rapnd
  class Notification
    attr_accessor :badge, :alert, :sound, :content_available, :category, :custom_properties, :mutable_content, :device_token
    
    def initialize(hash)
      [:badge, :alert, :sound, :device_token, :content_available, :category, :custom_properties, :mutable_content].each do |k|
        self.instance_variable_set("@#{k}".to_sym, hash[k]) if hash[k]
      end
      raise "Must provide device token: #{hash}" if self.device_token.nil?
      self.device_token = self.device_token.delete(' ')
    end
    
    def payload
      p = Hash.new
      [:badge, :alert, :sound, :category, :content_available, :mutable_content].each do |k|
        p[k.to_s.gsub('_','-').to_sym] = send(k) if send(k)
      end
      aps = {:aps => p}
      aps.merge!(custom_properties) if custom_properties
      aps
    end
    
    def json_payload
      j = ActiveSupport::JSON.encode(payload)
      raise "The payload #{j} is larger than allowed: #{j.length}" if j.size > 2048
      j
    end
    
    def to_bytes
      encoded_payload = json_payload
      
      [
        1,
        0, # identifier
        0, # expiry epoch time
        32, # device token length
        self.device_token,
        encoded_payload.bytesize,
        encoded_payload
      ].pack('CNNnH64nA*')
    end
  end
end
