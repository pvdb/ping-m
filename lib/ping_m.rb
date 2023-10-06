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
  TimeOut = Class.new(::OpenStruct)
  Summary = Class.new(::OpenStruct)
  Stats = Class.new(::OpenStruct)
  Header = Class.new(::OpenStruct)
  Footer = Class.new(::OpenStruct)

  class Error < StandardError; end
  # Your code goes here...
end

require 'ping/parser'
require 'ping/monitor'
require 'ping/processor'
require 'ping/statistics'
require 'ping/response'
