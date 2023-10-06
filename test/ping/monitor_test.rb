# frozen_string_literal: true

require 'test_helper'

module Ping
  class MonitorTest < Minitest::Test
    def test_that_it_has_a_name
      refute_nil ::Ping::Monitor::NAME
    end

    def test_that_it_has_a_version_number
      refute_nil ::Ping::Monitor::VERSION
    end

    def test_that_it_records_responses
      monitor = Ping::Monitor.new
      response = Ping::Factory.response

      response.stub :speed, :snail_like do
        monitor.record(response)

        refute_nil monitor.stats_for[:snail_like]
      end
    end

    def test_that_it_records_start_and_end_times
      monitor = Ping::Monitor.new

      assert_nil monitor.start_time
      assert_nil monitor.end_time
    end

    def test_that_it_sets_start_time_only_once
      monitor = Ping::Monitor.new

      now = Time.at(42)
      response = Ping::Factory.response(packet_received: now, rtt: 0)

      response.stub :speed, :snail_like do
        monitor.record(response)

        assert_equal now, monitor.start_time
      end

      later = Time.at(666)
      response = Ping::Factory.response(packet_received: later, rtt: 0)

      response.stub :speed, :speedy_gonzales do
        monitor.record(response)

        assert_equal now, monitor.start_time # ... and not later!
      end
    end

    def test_that_it_updates_end_time_every_time
      monitor = Ping::Monitor.new

      now = Time.at(42)
      response = Ping::Factory.response(packet_received: now)

      response.stub :speed, :snail_like do
        monitor.record(response)

        assert_equal now, monitor.end_time
      end

      later = Time.at(666)
      response = Ping::Factory.response(packet_received: later)

      response.stub :speed, :speedy_gonzales do
        monitor.record(response)

        assert_equal later, monitor.end_time # ... and not now!
      end
    end

    def test_that_it_calculates_duration
      monitor = Ping::Monitor.new

      now = Time.at(42)
      response = Ping::Factory.response(packet_received: now)

      response.stub :speed, :snail_like do
        monitor.record(response)

        assert_equal 0, monitor.duration
      end

      later = Time.at(666)
      response = Ping::Factory.response(packet_received: later)

      response.stub :speed, :speedy_gonzales do
        monitor.record(response)

        assert_equal 624, monitor.duration
      end
    end

    def test_that_it_processes_timeouts
      monitor = Ping::Monitor.new

      line = 'Request timeout for icmp_seq 91'
      monitor.process(line)

      assert_equal 1, monitor.transmitted
      assert_equal 0, monitor.received
      assert_equal 100, monitor.loss

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=51 time=119.126 ms'
      monitor.process(line)

      assert_equal 2, monitor.transmitted
      assert_equal 1, monitor.received
      assert_equal 50, monitor.loss

      assert_equal line, monitor.last_line_processed
      assert_nil monitor.last_line_ignored
    end

    def test_that_it_processes_roundtrips
      monitor = Ping::Monitor.new

      line = '64 bytes from 1.1.1.1: icmp_seq=0 ttl=51 time=119.126 ms'
      monitor.process(line)

      assert_equal 1, monitor.transmitted
      assert_equal 1, monitor.received
      assert_equal 0, monitor.loss

      line = 'Request timeout for icmp_seq 91'
      monitor.process(line)

      assert_equal 2, monitor.transmitted
      assert_equal 1, monitor.received
      assert_equal 50, monitor.loss

      assert_equal line, monitor.last_line_processed
      assert_nil monitor.last_line_ignored
    end

    def test_that_it_processes_ping_summary
      monitor = Ping::Monitor.new

      line = '1970 packets transmitted, 1950 packets received, 1.0% packet loss'
      monitor.process(line)

      summary = monitor.stats_for['ping']['summary']

      assert_equal '1,970', summary.transmitted
      assert_equal '1,950', summary.received
      assert_equal '1.0%', summary.loss

      assert_equal line, monitor.last_line_processed
      assert_nil monitor.last_line_ignored
    end

    def test_that_it_processes_ping_stats
      monitor = Ping::Monitor.new

      line = 'round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms'
      monitor.process(line)

      stats = monitor.stats_for['ping']['total']

      assert_in_delta(35.437, stats.min)
      assert_in_delta(64.677, stats.avg)
      assert_in_delta(107.174, stats.max)
      assert_in_delta(24.588, stats.stddev)

      assert_equal line, monitor.last_line_processed
      assert_nil monitor.last_line_ignored
    end

    def test_that_it_doesnt_process_ping_header
      monitor = Ping::Monitor.new

      line = 'PING 1.1.1.1 (1.1.1.1): 56 data bytes'
      monitor.process(line)

      assert_nil monitor.last_line_processed
      assert_equal line, monitor.last_line_ignored
    end
  end
end
