# frozen_string_literal: true

# this loads all of "ping-m"
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ping-m'
