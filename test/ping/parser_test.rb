# frozen_string_literal: true

require 'test_helper'

module Ping
  class ParserTest < Minitest::Test
    def test_that_it_identifies_windows_roundtrips
      line = 'Reply from 8.8.8.8: bytes=32 time=213ms TTL=115'

      assert Ping::Parser.rtt?(line)
    end

    def test_that_it_identifies_roundtrips
      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      assert Ping::Parser.rtt?(line)

      line = '08:33:15.476429 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      assert Ping::Parser.rtt?(line)

      line = '16:15:40.617136 64 bytes from 1.0.0.1: icmp_seq=1337 ttl=55 time=-9.545 ms'

      assert Ping::Parser.rtt?(line)

      line = '09:03:32.542825 64 bytes from 8.8.8.8: icmp_seq=23868 ttl=54 time=928.529 ms (DUP!)'

      assert Ping::Parser.rtt?(line)
    end

    def test_that_it_identifies_non_roundtrips
      line = 'Request timeout for icmp_seq 91'

      refute Ping::Parser.rtt?(line)

      line = '09:07:39.501590 Request timeout for icmp_seq 0'

      refute Ping::Parser.rtt?(line)
    end

    def test_that_it_parses_windows_roundtrips
      line = 'Reply from 8.8.8.8: bytes=32 time=213ms TTL=115'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)
    end

    def test_that_it_parses_roundtrips
      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)

      line = '08:33:15.476429 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)

      line = '16:15:40.617136 64 bytes from 1.0.0.1: icmp_seq=1337 ttl=55 time=-9.545 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)
    end

    # not sure how this can happen, or if it should, but it did!
    # hypothesis: NTP adjusted drift during the ping round trip?
    def test_that_it_parses_roundtrips_with_negative_time
      line = '64 bytes from 8.8.4.4: icmp_seq=1195 ttl=116 time=-57.508 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_equal Float('-57.508'), processed.rtt

      line = '08:04:59.180477 64 bytes from 8.8.4.4: icmp_seq=1195 ttl=116 time=-57.508 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_equal Float('-57.508'), processed.rtt
    end

    def test_that_it_unmarshalls_roundtrips_with_negative_time
      line = '64 bytes from 1.0.0.1: icmp_seq=1337 ttl=55 time=-9.545 ms'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        assert_equal packet_received, processed.packet_received
        assert_equal 64, processed.packet_size
        assert_equal IPAddr('1.0.0.1'), processed.ipaddr
        assert_equal 1337, processed.icmp_seq
        assert_equal 55, processed.ttl
        assert_in_delta(-9.545, processed.rtt)
        assert_nil processed.duplicate
        assert_nil processed.timeout
      end
    end

    def test_that_it_unmarshalls_duplicate_roundtrips
      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms (DUP!)'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        refute_nil processed.packet_received
        assert_equal 64, processed.packet_size
        assert_equal IPAddr('1.1.1.1'), processed.ipaddr
        assert_equal 0, processed.icmp_seq
        assert_equal 57, processed.ttl
        assert_in_delta(42.666, processed.rtt)
        assert_equal '(DUP!)', processed.duplicate
        assert_nil processed.timeout
      end
    end

    def test_that_it_unmarshalls_windows_roundtrips
      line = 'Reply from 8.8.8.8: bytes=32 time=213ms TTL=115'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        refute_nil processed.packet_received
        assert_equal 32, processed.packet_size
        assert_equal IPAddr('8.8.8.8'), processed.ipaddr
        assert_nil processed.icmp_seq
        assert_equal 115, processed.ttl
        assert_in_delta(213, processed.rtt)
        assert_nil processed.duplicate
        assert_nil processed.timeout
      end
    end

    def test_that_it_unmarshalls_roundtrips_without_apple_time
      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        refute_nil processed.packet_received
        assert_equal 64, processed.packet_size
        assert_equal IPAddr('1.1.1.1'), processed.ipaddr
        assert_equal 0, processed.icmp_seq
        assert_equal 57, processed.ttl
        assert_in_delta(42.666, processed.rtt)
        assert_nil processed.duplicate
        assert_nil processed.timeout
      end
    end

    def test_that_it_unmarshalls_roundtrips_with_apple_time
      line = '08:33:15.476429 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'
      packet_received = DateTime.strptime('08:33:15.476429', '%H:%M:%S.%L').to_time

      processed = Ping::Parser.process(line)

      # FIXME: rename `packet_received` to `response_received` to cover timeouts
      assert_equal packet_received, processed.packet_received
      assert_equal 64, processed.packet_size
      assert_equal IPAddr('1.1.1.1'), processed.ipaddr
      assert_equal 0, processed.icmp_seq
      assert_equal 57, processed.ttl
      assert_in_delta(42.666, processed.rtt)
      assert_nil processed.duplicate
      assert_nil processed.timeout
    end

    def test_that_it_identifies_windows_timeouts
      line = 'Request timed out.'

      assert Ping::Parser.timeout?(line)
    end

    def test_that_it_identifies_timeouts
      line = 'Request timeout for icmp_seq 91'

      assert Ping::Parser.timeout?(line)

      line = '09:07:39.501590 Request timeout for icmp_seq 91'

      assert Ping::Parser.timeout?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.timeout?(line)
    end

    def test_that_it_parses_timeouts_without_apple_time
      line = 'Request timeout for icmp_seq 91'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)
    end

    def test_that_it_parses_timeouts_with_apple_time
      line = '09:07:39.501590 Request timeout for icmp_seq 91'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Response, processed)
    end

    def test_that_it_unmarshalls_windows_timeouts
      line = 'Request timed out.'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        assert_equal packet_received, processed.packet_received
        assert_nil processed.packet_size
        assert_nil processed.ipaddr
        assert_nil processed.icmp_seq
        assert_nil processed.ttl
        assert_nil processed.rtt
        assert_nil processed.duplicate
        assert_equal 'timed out', processed.timeout
      end
    end

    def test_that_it_unmarshalls_timeouts_without_apple_time
      line = 'Request timeout for icmp_seq 91'
      packet_received = Time.at(42)

      Time.stub :now, packet_received do
        processed = Ping::Parser.process(line)

        assert_equal packet_received, processed.packet_received
        assert_nil processed.packet_size
        assert_nil processed.ipaddr
        assert_equal 91, processed.icmp_seq
        assert_nil processed.ttl
        assert_nil processed.rtt
        assert_nil processed.duplicate
        assert_equal 'timeout', processed.timeout
      end
    end

    def test_that_it_unmarshalls_timeouts_with_apple_time
      line = '09:07:39.501590 Request timeout for icmp_seq 91'
      packet_received = DateTime.strptime('09:07:39.501590', '%H:%M:%S.%L').to_time

      processed = Ping::Parser.process(line)

      # FIXME: rename `packet_received` to `response_received` to cover timeouts
      assert_equal packet_received, processed.packet_received
      assert_nil processed.packet_size
      assert_nil processed.ipaddr
      assert_equal 91, processed.icmp_seq
      assert_nil processed.ttl
      assert_nil processed.rtt
      assert_nil processed.duplicate
      assert_equal 'timeout', processed.timeout
    end

    def test_that_it_identifies_windows_summaries
      line = 'Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),'

      assert Ping::Parser.summary?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.summary?(line)
    end

    def test_that_it_identifies_summaries
      line = '197 packets transmitted, 195 packets received, 1.0% packet loss'

      assert Ping::Parser.summary?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.summary?(line)
    end

    def test_that_it_parses_windows_summaries
      line = 'Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Summary, processed)
    end

    def test_that_it_parses_summaries
      line = '197 packets transmitted, 195 packets received, 1.0% packet loss'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Summary, processed)
    end

    def test_that_it_unmarshalls_windows_summaries
      line = 'Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),'
      ping_summary = Ping::Parser.process(line)

      assert_equal '4', ping_summary.transmitted
      assert_equal '4', ping_summary.received
      assert_equal '0%', ping_summary.loss
    end

    def test_that_it_unmarshalls_summaries
      line = '197 packets transmitted, 195 packets received, 1.0% packet loss'
      ping_summary = Ping::Parser.process(line)

      assert_equal '197', ping_summary.transmitted
      assert_equal '195', ping_summary.received
      assert_equal '1.0%', ping_summary.loss
    end

    def test_that_it_identifies_windows_stats
      line = 'Minimum = 42ms, Maximum = 66ms, Average = 53ms'

      assert Ping::Parser.stats?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.stats?(line)
    end

    def test_that_it_identifies_stats
      line = 'round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms'

      assert Ping::Parser.stats?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.stats?(line)
    end

    def test_that_it_parses_windows_stats
      line = 'Minimum = 42ms, Maximum = 66ms, Average = 53ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Stats, processed)
    end

    def test_that_it_parses_stats
      line = 'round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Stats, processed)
    end

    def test_that_it_unmarshalls_stats
      line = 'round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms'
      stats = Ping::Parser.process(line)

      assert_in_delta(35.437, stats.min)
      assert_in_delta(64.677, stats.avg)
      assert_in_delta(107.174, stats.max)
      assert_in_delta(24.588, stats.stddev)
    end

    def test_that_it_identifies_windows_headers
      line = 'Pinging 8.8.4.4 with 32 bytes of data:'

      assert Ping::Parser.header?(line)

      line = 'Pinging dns.google [8.8.8.8] with 32 bytes of data:'

      assert Ping::Parser.header?(line)
    end

    def test_that_it_identifies_headers
      line = 'PING example.com (1.0.0.1): 56 data bytes'

      assert Ping::Parser.header?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.header?(line)
    end

    def test_that_it_parses_windows_headers
      line = 'Pinging 8.8.4.4 with 32 bytes of data:'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Header, processed)

      line = 'Pinging dns.google [8.8.8.8] with 32 bytes of data: '

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Header, processed)
    end

    def test_that_it_parses_headers
      line = 'PING example.com (1.0.0.1): 56 data bytes'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Header, processed)
    end

    def test_that_it_unmarshalls_windows_headers
      line = 'Pinging dns.google [8.8.8.8] with 32 bytes of data: '
      processed = Ping::Parser.process(line)

      assert_equal '8.8.8.8', processed.ipaddr
      assert_equal 'dns.google', processed.hostname
    end

    def test_that_it_unmarshalls_headers
      line = 'PING example.com (1.0.0.1): 56 data bytes'
      processed = Ping::Parser.process(line)

      assert_equal 'example.com', processed.hostname
      assert_equal '1.0.0.1', processed.ipaddr
    end

    def test_that_it_identifies_windows_footers
      line = 'Ping statistics for 1.0.0.1:'

      assert Ping::Parser.footer?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.footer?(line)
    end

    def test_that_it_identifies_footers
      line = '--- 1.1.1.1 ping statistics ---'

      assert Ping::Parser.footer?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.footer?(line)
    end

    def test_that_it_parses_windows_footers
      line = 'Ping statistics for 1.0.0.1:'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Footer, processed)
    end

    def test_that_it_parses_footers
      line = '--- 1.1.1.1 ping statistics ---'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Footer, processed)
    end

    def test_that_it_unmarshalls_windows_footers
      line = 'Ping statistics for 1.0.0.1:'
      processed = Ping::Parser.process(line)

      assert_equal '1.0.0.1', processed.hostname
    end

    def test_that_it_unmarshalls_footers
      line = '--- example.com ping statistics ---'
      processed = Ping::Parser.process(line)

      assert_equal 'example.com', processed.hostname
    end

    def test_that_it_identifies_errors
      line = 'ping: sendto: No route to host'

      assert Ping::Parser.error?(line)

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.error?(line)
    end

    def test_that_it_parses_errors
      line = 'ping: sendto: No route to host'

      refute_nil processed = Ping::Parser.process(line)
      assert_instance_of(Error, processed)
    end

    def test_that_it_unmarshalls_errors
      line = 'ping: sendto: No route to host'
      processed = Ping::Parser.process(line)

      assert_equal 'sendto: No route to host', processed.message
    end

    def test_that_it_identifies_recorded_roundtrips
      [
        "1549101486\t1.1.1.1\t28.779", # with tabs, '%d' format
        "1549101486.394\t1.1.1.1\t28.779", # with tabs, '%f' format
        '1549101486    1.1.1.1    28.779', # with spaces, '%d' format
        '1549101486.394    1.1.1.1    28.779', # with spaces, '%f' format
      ].each do |line|
        assert Ping::Parser.rrtt?(line)
      end

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms'

      refute Ping::Parser.rrtt?(line)
    end

    def test_that_it_parses_recorded_roundtrips
      [
        "1549101486\t1.1.1.1\t28.779", # with tabs, '%d' format
        "1549101486.394\t1.1.1.1\t28.779", # with tabs, '%f' format
        '1549101486    1.1.1.1    28.779', # with spaces, '%d' format
        '1549101486.394    1.1.1.1    28.779', # with spaces, '%f' format
      ].each do |line|
        refute_nil processed = Ping::Parser.process(line)
        assert_instance_of(Response, processed)
      end
    end

    def test_that_it_unmarshalls_recorded_roundtrips
      [
        "1549101486\t1.1.1.1\t28.779", # with tabs, '%d' format
        '1549101486    1.1.1.1    28.779', # with spaces, '%d' format
      ].each do |line|
        response = Ping::Parser.process(line)

        assert_equal Float('28.779'), response.rtt
        assert_equal IPAddr('1.1.1.1'), response.ipaddr
        # rubocop:disable Style/NumericLiterals
        assert_equal Time.at(1549101486), response.packet_received
        # rubocop:enable Style/NumericLiterals
      end

      [
        "1549101486.394\t1.1.1.1\t28.779", # with tabs, '%f' format
        '1549101486.394    1.1.1.1    28.779', # with spaces, '%f' format
      ].each do |line|
        response = Ping::Parser.process(line)

        assert_equal Float('28.779'), response.rtt
        assert_equal IPAddr('1.1.1.1'), response.ipaddr
        # rubocop:disable Style/NumericLiterals
        assert_equal Time.at(1549101486.394), response.packet_received
        # rubocop:enable Style/NumericLiterals
      end
    end
  end
end
