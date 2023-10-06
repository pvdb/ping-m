# frozen_string_literal: true

require 'date'

class Time
  #
  # `ping --apple-time 1.1.1.1` outputs something akin to...
  #
  # 08:33:15.476429 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms
  #
  PING_APPLE_TIME = /\A\d{2}:\d{2}:\d{2}.\d+\z/

  def self.from(apple_time)
    DateTime.strptime(apple_time, '%H:%M:%S.%L').to_time
  end
end
