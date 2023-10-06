if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'ping-m'

module Ping
  module Factory
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.response(options = {})
      packet_received = options[:packet_received] || Response.time_now
      packet_size = options[:packet_size] || 64
      ipaddr = options[:ipaddr] || '192.168.0.1'
      icmp_seq = options[:icmp_seq] || 666
      ttl = options[:ttl] || 57
      rtt = options[:rtt] || 42.666
      duplicate = options[:duplicate] || nil
      timeout = options[:timeout] || nil

      Ping::Response.new(packet_received, packet_size, ipaddr, icmp_seq, ttl, rtt, duplicate, timeout)
    end

    def self.timeout(options = {})
      response(options.merge(timeout: 'timeout'))
    end

    def self.duplicate(options = {})
      response(options.merge(duplicate: '(DUP!)'))
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
  end

  class Monitor
    # making public, but for testing purposes only!
    attr_accessor :start_time, :end_time, :duration
    attr_accessor :transmitted, :received, :loss
    attr_accessor :stats_for
  end
end

require 'minitest/pride'
require 'minitest/autorun'
