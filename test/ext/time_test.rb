# frozen_string_literal: true

require 'test_helper'

class TimeTest < Minitest::Test
  def test_that_it_matches_apple_time
    assert_match Time::PING_APPLE_TIME, '08:33:15.476429'
  end

  def test_that_it_does_not_match_other_times
    refute_match Time::PING_APPLE_TIME, '8:33:15.476429'
    refute_match Time::PING_APPLE_TIME, '08:33:15'
    refute_match Time::PING_APPLE_TIME, 'at 08:33:15.476429'
    refute_match Time::PING_APPLE_TIME, '08:33:15x476429'
  end

  def test_that_it_parses_apple_time
    time = Time.from('08:33:15.476429').utc

    assert_equal [8, 33, 15], [time.hour, time.min, time.sec]
    assert_equal 476_429, time.usec
  end
end
