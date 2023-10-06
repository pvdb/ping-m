# frozen_string_literal: true

require 'time'
require 'json'
require 'English'
require 'ostruct'
require 'rainbow'

require 'ext/time'
require 'ext/json'
require 'ext/ipaddr'
require 'ext/kernel'
require 'ext/ostruct'
require 'ext/commify'
require 'ext/match_data'

module Ping
  class TimeOut < ::OpenStruct
  end

  class Summary < ::OpenStruct
  end

  class Stats < ::OpenStruct
  end

  class Header < ::OpenStruct
  end

  class Footer < ::OpenStruct
  end

  class Error < StandardError; end
  # Your code goes here...
end

require 'ping/parser'
require 'ping/monitor'
require 'ping/processor'
require 'ping/statistics'
require 'ping/response'
