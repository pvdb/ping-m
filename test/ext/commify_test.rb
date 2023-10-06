# frozen_string_literal: true

require 'test_helper'

class CommifyTest < Minitest::Test
  def test_that_it_leaves_small_integers_alone
    assert_equal '0', 0.commify
    assert_equal '999', 999.commify
  end

  def test_that_it_commifies_integers
    assert_equal '1,000', 1000.commify
    assert_equal '1,234,567', 1_234_567.commify
  end

  def test_that_it_commifies_negative_integers
    assert_equal '-1,234,567', -1_234_567.commify
  end

  def test_that_it_commifies_floats
    assert_equal '1,234,567.891', 1_234_567.891.commify
  end

  def test_that_it_does_not_commify_decimals
    assert_equal '1,234.5678', 1234.5678.commify
    assert_equal '1,234.5678', '1234.5678'.commify
    assert_equal '0.123456', 0.123456.commify
  end

  def test_that_it_commifies_strings
    assert_equal '1,234,567', '1234567'.commify
    assert_equal 'abc', 'abc'.commify
  end
end
