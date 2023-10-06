# frozen_string_literal: true

require 'ipaddr'

module Kernel
  # rubocop:disable Naming/MethodName
  def IPAddr(addr = '::', family = Socket::AF_UNSPEC)
    IPAddr.new(addr, family)
  end
  # rubocop:enable Naming/MethodName

  def private_network
    # https://en.wikipedia.org/wiki/Private_network
    %(192.168.0.0)
  end

  def default_gateway
    if RUBY_PLATFORM =~ /darwin/i
      `route get default`
        .lines.grep(/\A\s*gateway: /).first
        .strip.gsub(/\A\s*gateway: /, '')
    else
      %(192.168.0.1)
    end
  end
end

unless IPAddr.instance_methods.include? :private?
  class IPAddr
    def private?
      case @family
      when Socket::AF_INET
        @addr & 0xff000000 == 0x0a000000 ||    # 10.0.0.0/8
          @addr & 0xfff00000 == 0xac100000 ||  # 172.16.0.0/12
          @addr & 0xffff0000 == 0xc0a80000     # 192.168.0.0/16
      when Socket::AF_INET6
        @addr & 0xfe00_0000_0000_0000_0000_0000_0000_0000 == 0xfc00_0000_0000_0000_0000_0000_0000_0000
      else
        raise AddressFamilyError, 'unsupported address family'
      end
    end
  end
end
