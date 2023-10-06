# frozen_string_literal: true

require 'test_helper'

class OpenStructTest < Minitest::Test
  def test_that_it_converts_to_json
    open_struct = OpenStruct.new(host: '1.1.1.1', rtt: 42.666)

    assert_equal '{"host":"1.1.1.1","rtt":42.666}', open_struct.to_json
  end

  def test_that_it_converts_nested_to_json
    open_structs = [OpenStruct.new(seq: 1), OpenStruct.new(seq: 2)]

    assert_equal '[{"seq":1},{"seq":2}]', open_structs.to_json
  end

  def test_that_it_converts_empty_to_json
    assert_equal '{}', OpenStruct.new.to_json
  end

  def test_that_it_honours_json_generator_options
    assert_equal %({\n  "seq": 1\n}), JSON.pretty_generate(OpenStruct.new(seq: 1))
  end
end
