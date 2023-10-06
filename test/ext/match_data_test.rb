# frozen_string_literal: true

require 'test_helper'

class MatchDataTest < Minitest::Test
  def test_that_it_symbolises_named_captures
    match_data = /(?<seq>\d+) (?<ip>\S+)/.match('42 1.1.1.1')

    assert_equal({ seq: '42', ip: '1.1.1.1' }, match_data.symbolised_named_captures)
  end

  def test_that_it_includes_unmatched_named_captures
    match_data = /(?<seq>\d+)(?<dup> \(DUP!\))?/.match('42')

    assert_equal({ seq: '42', dup: nil }, match_data.symbolised_named_captures)
  end

  def test_that_it_returns_empty_hash_without_named_captures
    assert_empty(/\d+/.match('42').symbolised_named_captures)
  end
end
