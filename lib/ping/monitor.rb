# frozen_string_literal: true

module Ping
  class Monitor
    NAME = 'ping-m'
    VERSION = '1.0.0'

    attr_reader :last_line_ignored
    attr_reader :last_line_processed

    def initialize
      @start_time = nil
      @end_time = nil
      @duration = nil

      @transmitted = 0
      @received = 0
      @loss = 0

      @stats_for = Hash.new do |stats, key|
        speed = !%w[timings summary speeds ping].include?(key)
        stats[key] = speed ? Statistics.new : OpenStruct.new
      end

      # to ensure hash order
      @stats_for['timings']
      @stats_for['summary']
      @stats_for['speeds']
    end

    def process(line)
      @last_line_ignored = nil
      @last_line_processed = line

      case processed = Parser.process(line)
      when Response
        # 64 bytes from 1.1.1.1: icmp_seq=0 ttl=51 time=119.126 ms
        # Request timeout for icmp_seq 91
        record(processed)
        processed
      when TimeOut
        # Request timeout for icmp_seq 91
        # record(nil)
        # nil
      when Error
        # ping: sendto: No route to host
        @last_line_processed = nil
        @last_line_ignored = nil
        nil
      when Summary
        # 197 packets transmitted, 195 packets received, 1.0% packet loss
        @stats_for['ping']['summary'] = processed
        nil
      when Stats
        # round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms
        @stats_for['ping']['total'] = processed
        nil
      else
        @last_line_processed = nil
        @last_line_ignored = line
        nil
      end
    end

    def record(response)
      @transmitted += 1
      @received += 1 unless response.timeout?
      @loss = (@transmitted - @received) * 100.0 / @transmitted

      @stats_for['summary'].transmitted = @transmitted.commify
      @stats_for['summary'].received = @received.commify
      @stats_for['summary'].loss = format('%<loss>0.1f%%', loss: @loss)

      return unless response

      # set "start time" only once!
      @start_time ||= response.packet_sent
      @stats_for['timings'].start_time ||= @start_time.iso8601

      # update "end time" every time!
      @end_time = response.packet_received
      @stats_for['timings'].end_time = @end_time.iso8601

      # update "duration" every time!
      @duration = (@end_time - @start_time).round(0)
      @stats_for['timings'].duration = format(
        '%<duration>d seconds',
        duration: @duration,
      )

      @stats_for['total'].update_with(response)
      @stats_for[response.speed].update_with(response)
    end

    def latest_stats
      @stats_for['total']
    end

    def speed_stats
      total = @stats_for['total'].count.to_f
      Response::SPEEDS.map { |speed|
        next unless @stats_for.key?(speed)

        count = @stats_for[speed].count.to_f
        ratio = count / total * 100

        [speed, format(
          '(%<count>d/%<total>d) %<ratio>0.2f%%',
          count: count,
          total: total,
          ratio: ratio,
        )]
      }.compact.to_h
    end

    def to_json(*args)
      @stats_for['speeds'] = speed_stats
      @stats_for.to_json(args)
    end
  end
end
