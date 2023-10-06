# frozen_string_literal: true

require 'ipaddr'

module Kernel
  # rubocop:disable-next Naming/MethodName
  def IPAddr(addr = '::', family = Socket::AF_UNSPEC)
    IPAddr.new(addr, family)
  end

  def private_network
    # https://en.wikipedia.org/wiki/Private_network
    %(192.168.0.0)
  end

  def default_gateway
    if RUBY_PLATFORM =~ /darwin/i
      `route -n get default` # -n: numeric address, not hostname
        .lines.grep(/\A\s*gateway: /).first
        .strip.gsub(/\A\s*gateway: /, '')
    else
      %(192.168.0.1)
    end
  end
end
