# frozen_string_literal: true

require 'test_helper'

class JSONTest < Minitest::Test
  def test_that_it_leaves_json_without_single_quotes_alone
    json = '{"host":"1.1.1.1"}'

    assert_equal json, JSON.escape(json)
  end

  def test_that_it_escapes_single_quotes
    assert_equal %({"name":"it'"'"'s"}), JSON.escape(%({"name":"it's"}))
  end

  def test_that_escaped_json_survives_single_quoting_in_the_shell
    json = %({"name":"it's"})

    assert_equal json, `printf '%s' '#{JSON.escape(json)}'`
  end
end
