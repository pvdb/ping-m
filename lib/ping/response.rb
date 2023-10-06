# frozen_string_literal: true

module Ping
  FIELDS = %i[
    packet_sent
    packet_received
    packet_size
    ipaddr
    icmp_seq
    ttl
    rtt
    duplicate
    timeout
  ].freeze

  # FIXME: rename `packet_received` to `response_received` to cover timeouts

  Response = Struct.new(*FIELDS)

  class Response
    def self.time_now
      Time.now.utc
    end

    def self.time_from(apple_time)
      Time.from(apple_time).utc
    end

    def self.time_at(seconds_with_frac)
      Time.at(seconds_with_frac).utc
    end

    def self.to_local_24hr(time)
      time.getlocal.strftime('%T')
    end

    private def normalize_packet_received(packet_received)
      case packet_received
      when nil
        # `ping` output typically has no timestamp
        Response.time_now
      when Time::PING_APPLE_TIME
        # parse the `--apple-time` optional timestamp
        Response.time_from(packet_received)
      when String
        # previously recorded ping-m output
        Response.time_at(Float(packet_received))
      when Numeric
        # mainly (solely?) tests
        Response.time_at(packet_received)
      else
        packet_received
      end
    end

    private def normalize_packet_size(packet_size)
      packet_size.is_a?(String) ? Integer(packet_size) : packet_size
    end

    private def normalize_ipaddr(ipaddr)
      ipaddr.is_a?(String) ? IPAddr.new(ipaddr) : ipaddr
    end

    private def normalize_icmp_seq(icmp_seq)
      icmp_seq.is_a?(String) ? Integer(icmp_seq) : icmp_seq
    end

    private def normalize_rtt(rtt)
      rtt.is_a?(String) ? Float(rtt) : rtt
    end

    private def normalize_ttl(ttl)
      ttl.is_a?(String) ? Integer(ttl) : ttl
    end

    private def calculate_packet_sent(packet_received, rtt, timeout)
      rtt = 1_000 if timeout # default ping timeout is 1 second
      packet_sent = (packet_received.to_f - (rtt / 1_000)).round(6)
      Time.at(packet_sent) # ping's packet_received - ping's RTT
    end

    def initialize(packet_received, packet_size, ipaddr, icmp_seq, ttl, rtt, duplicate, timeout)
      packet_received = normalize_packet_received(packet_received)
      packet_size = normalize_packet_size(packet_size)
      ipaddr = normalize_ipaddr(ipaddr)
      icmp_seq = normalize_icmp_seq(icmp_seq)
      ttl = normalize_ttl(ttl)
      rtt = normalize_rtt(rtt)

      packet_sent = calculate_packet_sent(packet_received, rtt, timeout)

      super(packet_sent, packet_received, packet_size, ipaddr, icmp_seq, ttl, rtt, duplicate, timeout)
    end

    def negative?
      rtt.negative?
    end

    def duplicate?
      !duplicate.nil?
    end

    def timeout?
      !timeout.nil?
    end

    def ipaddr_private?
      ipaddr.private?
    end

    def ipaddr_space
      ipaddr_private? ? :private : :public
    end

    RANGES = {
      public: {
        unknown: -Float::INFINITY...0,
        fast:                   0...50,
        somewhat_slow:         50...100,
        really_slow:          100...1_000,
        terribly_slow:      1_000...10_000,
        extremely_slow:    10_000..Float::INFINITY,
      }.freeze,

      private: {
        unknown: -Float::INFINITY...0,
        fast:                   0...10,
        somewhat_slow:         10...20,
        really_slow:           20...100,
        terribly_slow:        100...1_000,
        extremely_slow:     1_000..Float::INFINITY,
      }.freeze,
    }.freeze

    def speed
      return :timeout if timeout # no rtt

      RANGES[ipaddr_space].find { |_, range| range.include? rtt }.first
    end

    COLOURS = {
      unknown: :inverse,
      fast: :green,
      somewhat_slow: :yellow,
      really_slow: :orange,
      terribly_slow: :orangered,
      extremely_slow: :red,
      timeout: :darkred,
    }.freeze

    SPEEDS = COLOURS.keys.dup.freeze

    def colour
      COLOURS[speed]
    end

    TIMEOUT_FORMAT = %w[
      %<icmp_seq>15s
      %<time_24hr>s
      %<timeout>s
    ].join(' ').freeze

    RTT_FORMAT = %w[
      %<icmp_seq>15s
      %<time_24hr>s
      %<ipaddr>s
      ->
      %<rtt>20s
      %<blocks>s
    ].join(' ').freeze

    def to_tty(rainbow)
      time_24hr = Response.to_local_24hr(packet_sent)
      rainbow_seq = rainbow.wrap("##{icmp_seq}").send(duplicate? ? :red : :blue)

      if timeout
        timeout = rainbow.wrap('[timeout]').send(:red)

        format(
          TIMEOUT_FORMAT,
          time_24hr: time_24hr,
          icmp_seq: rainbow_seq,
          timeout: timeout,
        )
      else
        padded_rtt = format('%0.3fms', rtt)
        rainbow_rtt = rainbow.wrap(padded_rtt).send('bright')
        blocks = if negative?
                   rainbow.wrap(Blocks(1, 40)).send('red')
                 else
                   rainbow.wrap(Blocks(rtt, 40)).send(colour)
                 end

        format(
          RTT_FORMAT,
          icmp_seq: rainbow_seq,
          time_24hr: time_24hr,
          ipaddr: ipaddr,
          rtt: rainbow_rtt,
          blocks: blocks,
        )
      end
    end

    # rubocop:disable Style/FormatStringToken
    def to_s
      # FIXME: no ipaddr nor rtt if timeout
      format("%d\t%s\t%0.3f", packet_sent, ipaddr, rtt)
    end
    # rubocop:enable Style/FormatStringToken
  end
end
