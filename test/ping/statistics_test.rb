# frozen_string_literal: true

require 'test_helper'

module Ping
  class StatisticsTest < Minitest::Test
    def test_that_it_updates_counts
      statistics = Ping::Statistics.new

      assert_nil statistics.count

      first_response = Ping::Factory.response
      statistics.update_with(first_response)

      assert_equal 1, statistics.count

      second_response = Ping::Factory.response
      statistics.update_with(second_response)

      assert_equal 2, statistics.count
    end

    def test_that_it_updates_avgs
      statistics = Ping::Statistics.new

      assert_nil statistics.avg

      first_response = Ping::Factory.response(rtt: 42.42)
      statistics.update_with(first_response)

      assert_in_delta(42.42, statistics.avg)

      second_response = Ping::Factory.response(rtt: 666.666)
      statistics.update_with(second_response)

      assert_in_delta(354.543, statistics.avg)
    end

    def test_that_it_updates_mins
      statistics = Ping::Statistics.new

      assert_nil statistics.min

      first_response = Ping::Factory.response(rtt: 42.42)
      statistics.update_with(first_response)

      assert_in_delta(42.42, statistics.min)

      second_response = Ping::Factory.response(rtt: 666.666)
      statistics.update_with(second_response)

      assert_in_delta(42.42, statistics.min)

      second_response = Ping::Factory.response(rtt: 10.101)
      statistics.update_with(second_response)

      assert_in_delta(10.101, statistics.min)
    end

    def test_that_it_updates_maxs
      statistics = Ping::Statistics.new

      assert_nil statistics.max

      first_response = Ping::Factory.response(rtt: 42.42)
      statistics.update_with(first_response)

      assert_in_delta(42.42, statistics.max)

      second_response = Ping::Factory.response(rtt: 666.666)
      statistics.update_with(second_response)

      assert_in_delta(666.666, statistics.max)

      second_response = Ping::Factory.response(rtt: 10.101)
      statistics.update_with(second_response)

      assert_in_delta(666.666, statistics.max)
    end

    def test_that_it_merges_statistics
      first_stats = Ping::Statistics.new(count: 42)
      second_stats = Ping::Statistics.new(min: 1, avg: 2, max: 3)

      expected_stats = Ping::Statistics.new(count: 42, min: 1, avg: 2, max: 3)
      merged_stats = first_stats.merge(second_stats)

      assert_equal expected_stats, merged_stats

      assert_nil merged_stats.stddev
    end

    def test_that_it_doesnt_override_on_merge
      first_stats = Ping::Statistics.new(count: 42)
      second_stats = Ping::Statistics.new(count: 666)

      assert_raises ArgumentError do
        first_stats.merge(second_stats)
      end
    end
  end
end
