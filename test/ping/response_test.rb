# frozen_string_literal: true

require 'test_helper'

module Ping
  class ResponseTest < Minitest::Test
    def test_timezone_for_time_now
      assert_equal 'UTC', Response.time_now.zone
    end

    def test_timezone_for_apple_time
      assert_equal 'UTC', Response.time_from('08:33:15.476429').zone
    end

    def test_timezone_for_time_at
      assert_equal 'UTC', Response.time_at(Float('1591522631.103503')).zone
    end

    def test_that_it_has_a_packet_received
      packet_received_float = 42.666
      packet_received_object = Time.at(packet_received_float)

      response = Ping::Factory.response(packet_received: packet_received_float)

      assert_instance_of Time, response.packet_received
      assert_equal packet_received_object, response.packet_received

      response = Ping::Factory.response(packet_received: packet_received_object)

      assert_instance_of Time, response.packet_received
      assert_equal packet_received_object, response.packet_received

      packet_received_fixnum = 42
      packet_received_object = Time.at(packet_received_fixnum)

      response = Ping::Factory.response(packet_received: packet_received_fixnum)

      assert_instance_of Time, response.packet_received
      assert_equal packet_received_object, response.packet_received

      response = Ping::Factory.response(packet_received: packet_received_object)

      assert_instance_of Time, response.packet_received
      assert_equal packet_received_object, response.packet_received
    end

    def test_that_it_has_an_packet_size
      packet_size_string = '64'
      packet_size_object = Integer(packet_size_string)

      response = Ping::Factory.response(packet_size: packet_size_string)

      assert_instance_of Integer, response.packet_size
      assert_equal packet_size_object, response.packet_size

      response = Ping::Factory.response(packet_size: packet_size_object)

      assert_instance_of Integer, response.packet_size
      assert_equal packet_size_object, response.packet_size
    end

    def test_that_it_has_an_ip_address
      ipaddr_string = '192.168.0.1'
      ipaddr_object = IPAddr(ipaddr_string)

      response = Ping::Factory.response(ipaddr: ipaddr_string)

      assert_instance_of IPAddr, response.ipaddr
      assert_equal ipaddr_object, response.ipaddr

      response = Ping::Factory.response(ipaddr: ipaddr_object)

      assert_instance_of IPAddr, response.ipaddr
      assert_equal ipaddr_object, response.ipaddr
    end

    def test_that_it_has_an_icmp_seq
      icmp_seq_string = '666'
      icmp_seq_object = Integer(icmp_seq_string)

      response = Ping::Factory.response(icmp_seq: icmp_seq_string)

      assert_instance_of Integer, response.icmp_seq
      assert_equal icmp_seq_object, response.icmp_seq

      response = Ping::Factory.response(icmp_seq: icmp_seq_object)

      assert_instance_of Integer, response.icmp_seq
      assert_equal icmp_seq_object, response.icmp_seq
    end

    def test_that_it_has_a_ttl
      ttl_integer = 57
      ttl_string = ttl_integer.to_s

      response = Ping::Factory.response(ttl: ttl_integer)

      assert_instance_of Integer, response.ttl
      assert_equal ttl_integer, response.ttl

      response = Ping::Factory.response(ttl: ttl_string)

      assert_instance_of Integer, response.ttl
      assert_equal ttl_integer, response.ttl
    end

    def test_that_it_has_a_rtt
      rtt_float = 42.666
      rtt_string = rtt_float.to_s

      response = Ping::Factory.response(rtt: rtt_float)

      assert_instance_of Float, response.rtt
      assert_equal rtt_float, response.rtt

      response = Ping::Factory.response(rtt: rtt_string)

      assert_instance_of Float, response.rtt
      assert_equal rtt_float, response.rtt
    end

    def test_that_it_defaults_packet_received
      options = {
        ipaddr: ipaddr = IPAddr('168.0.0.1'),
        packet_received: packet_received = Time.at(42.666),
        rtt: rtt = 333.111, # ping RTTs are in milliseconds
      }

      Time.stub :now, packet_received do
        response = Ping::Factory.response(options)

        assert_equal packet_received, response.packet_received
        assert_equal ipaddr, response.ipaddr
        assert_equal rtt, response.rtt
      end
    end

    def test_that_it_calculates_packet_sent
      options = {
        ipaddr: IPAddr('168.0.0.1'),
        packet_received: Time.at(42.666),
        rtt: 333.111, # ping RTTs are in milliseconds
      }

      response = Ping::Factory.response(options)

      assert_equal Time.at(42.332889).to_f, response.packet_sent.to_f
      assert_equal Time.at(42.332889).to_i, response.packet_sent.to_i
      assert_equal Time.at(42.332889), response.packet_sent
    end

    def test_that_it_identifies_private_ipaddr
      response = Ping::Factory.response(ipaddr: '192.168.0.1')

      assert_predicate response, :ipaddr_private?
      assert_equal :private, response.ipaddr_space
    end

    def test_that_it_identifies_public_ipaddr
      response = Ping::Factory.response(ipaddr: '1.1.1.1')

      refute_predicate response, :ipaddr_private?
      assert_equal :public, response.ipaddr_space
    end

    def test_that_it_identifies_negative_rtt
      response = Ping::Factory.response(rtt: 22.1119)

      refute_predicate response, :negative?

      response = Ping::Factory.response(rtt: -22.1119)

      assert_predicate response, :negative?
    end

    def test_that_it_identifies_roundtrip
      response = Ping::Factory.response

      refute_predicate response, :timeout?
      refute_predicate response, :duplicate?
    end

    def test_that_it_identifies_timeout
      timeout = Ping::Factory.timeout

      assert_predicate timeout, :timeout?
      refute_predicate timeout, :duplicate?
    end

    def test_that_it_identifies_duplicate
      duplicate = Ping::Factory.duplicate

      refute_predicate duplicate, :timeout?
      assert_predicate duplicate, :duplicate?
    end

    def test_that_it_determines_correct_colour
      response = Ping::Factory.response

      response.stub :speed, :fast do
        assert_equal :green, response.colour
      end

      response.stub :speed, :somewhat_slow do
        assert_equal :yellow, response.colour
      end

      response.stub :speed, :really_slow do
        assert_equal :orange, response.colour
      end

      response.stub :speed, :terribly_slow do
        assert_equal :orangered, response.colour
      end

      response.stub :speed, :extremely_slow do
        assert_equal :red, response.colour
      end

      response.stub :speed, :timeout do
        assert_equal :darkred, response.colour
      end
    end
  end
end
