# frozen_string_literal: true

require 'test_helper'

class KernelTest < Minitest::Test
  def setup
    skip 'Windows uses an ASCII fallback' if RUBY_PLATFORM.match?(/mingw|mswin/i)
  end

  def test_that_it_returns_no_blocks_for_zero
    assert_equal '', Blocks(0)
  end

  def test_that_it_returns_partial_blocks
    assert_equal PARTIALS[1], Blocks(1)
    assert_equal PARTIALS[4], Blocks(4)
    assert_equal PARTIALS[7], Blocks(7)
  end

  def test_that_it_returns_full_blocks
    assert_equal FULL, Blocks(8)
    assert_equal FULL * 2, Blocks(16)
  end

  def test_that_it_returns_full_and_partial_blocks
    assert_equal FULL + PARTIALS[1], Blocks(9)
    assert_equal (FULL * 4) + PARTIALS[7], Blocks(39, 5)
  end

  def test_that_it_ignores_fractions_of_eighths
    assert_equal Blocks(9), Blocks(9.9)
  end

  def test_that_it_caps_blocks_at_max
    assert_equal FULL * 5, Blocks(40, 5)
    assert_equal FULL * 5, Blocks(100, 5)
  end
end
