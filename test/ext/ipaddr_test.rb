# frozen_string_literal: true

require 'test_helper'

class IPAddrTest < Minitest::Test
  ROUTE_GET_DEFAULT = <<~ROUTE
       route to: default
    destination: default
           mask: default
        gateway: 192.168.0.1
      interface: en0
          flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
  ROUTE

  def test_that_it_creates_ipv4_addresses
    assert_equal IPAddr.new('192.168.0.1'), IPAddr('192.168.0.1')
    assert_predicate IPAddr('192.168.0.1'), :ipv4?
  end

  def test_that_it_creates_ipv6_addresses
    assert_equal IPAddr.new('::'), IPAddr()
    assert_predicate IPAddr('::1', Socket::AF_INET6), :ipv6?
  end

  def test_that_it_returns_private_network
    assert_equal '192.168.0.0', private_network
  end

  def test_that_it_returns_default_gateway
    skip 'only parses `route` output on macOS' unless RUBY_PLATFORM.match?(/darwin/i)

    stub(:`, ROUTE_GET_DEFAULT) do
      assert_equal '192.168.0.1', default_gateway
    end
  end

  def test_that_it_does_not_resolve_default_gateway_name
    skip 'only runs `route` on macOS' unless RUBY_PLATFORM.match?(/darwin/i)

    commands = []
    route = ->(command) { (commands << command) && ROUTE_GET_DEFAULT }

    stub(:`, route) { default_gateway }

    assert_equal ['route -n get default'], commands
  end

  def test_that_it_identifies_private_ipv4_addresses
    assert_predicate IPAddr('10.1.2.3'), :private?
    assert_predicate IPAddr('172.16.0.1'), :private?
    assert_predicate IPAddr('192.168.0.1'), :private?
  end

  def test_that_it_identifies_public_ipv4_addresses
    refute_predicate IPAddr('1.1.1.1'), :private?
    refute_predicate IPAddr('8.8.8.8'), :private?
    refute_predicate IPAddr('172.32.0.1'), :private?
  end

  def test_that_it_identifies_private_ipv6_addresses
    assert_predicate IPAddr('fc00::1'), :private?
    refute_predicate IPAddr('2606:4700:4700::1111'), :private?
  end
end
