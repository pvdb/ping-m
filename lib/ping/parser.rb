# frozen_string_literal: true

module Ping
  #
  # MacOS X:
  # --------
  #
  # PING example.com (93.184.216.34): 56 data bytes
  # 64 bytes from 93.184.216.34: icmp_seq=0 ttl=51 time=123.490 ms
  # 64 bytes from 93.184.216.34: icmp_seq=1 ttl=51 time=99.936 ms
  # 64 bytes from 93.184.216.34: icmp_seq=2 ttl=51 time=101.444 ms
  # 64 bytes from 93.184.216.34: icmp_seq=3 ttl=51 time=96.691 ms
  # Request timeout for icmp_seq 4
  # Request timeout for icmp_seq 5
  # 64 bytes from 93.184.216.34: icmp_seq=6 ttl=51 time=91.611 ms
  # 64 bytes from 93.184.216.34: icmp_seq=7 ttl=51 time=167.093 ms
  # 64 bytes from 93.184.216.34: icmp_seq=8 ttl=51 time=167.078 ms
  #
  # --- example.com ping statistics ---
  # 4 packets transmitted, 4 packets received, 0.0% packet loss
  # round-trip min/avg/max/stddev = 96.691/105.390/123.490/10.590 ms
  #
  # Windows:
  # --------
  #
  # Pinging dns.google [8.8.4.4] with 32 bytes of data:
  # Reply from 8.8.4.4: bytes=32 time=76ms TTL=115
  # Reply from 8.8.4.4: bytes=32 time=60ms TTL=115
  # Reply from 8.8.4.4: bytes=32 time=86ms TTL=115
  # Reply from 8.8.4.4: bytes=32 time=94ms TTL=115
  #
  # Ping statistics for 8.8.4.4:
  #     Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
  # Approximate round trip times in milli-seconds:
  #     Minimum = 60ms, Maximum = 94ms, Average = 79ms
  #
  class Parser
    # Pinging 8.8.4.4 with 32 bytes of data:
    # Pinging dns.google [8.8.8.8] with 32 bytes of data:
    W_HEADER = /\A
      Pinging\ (?<hostname>.+)\ \[(?<ipaddr>.+)\]\ with\ (?<size>\d+)\ bytes\ of\ data:
      |
      Pinging\ (?<ipaddr>.+)\ with\ (?<size>\d+)\ bytes\ of\ data:
    \z/x

    # PING example.com (93.184.216.34): 56 data bytes
    HEADER = /\A
      PING\ (?<hostname>.+)\ \((?<ipaddr>.+)\):\ (?<size>\d+)\ data\ bytes
    \z/x

    def self.header?(line)
      HEADER.match?(line) || W_HEADER.match?(line)
    end

    def self.header_from(captures)
      Header.new(captures)
    end

    # Ping statistics for 1.0.0.1:
    W_FOOTER = /\A
      Ping\ statistics\ for\ (?<hostname>.+):
      |
      Approximate\ round\ trip\ times\ in\ milli-seconds:
    \z/x

    # --- example.com ping statistics ---
    FOOTER = /\A
      ---\ (?<hostname>.+)\ ping\ statistics\ ---
    \z/x

    def self.footer?(line)
      FOOTER.match?(line) || W_FOOTER.match?(line)
    end

    def self.footer_from(captures)
      Footer.new(captures)
    end

    # ping: sendto: No route to host
    ERROR = /\A
      ping:\ (?<error>.+)
    \z/x

    def self.error?(line)
      ERROR.match?(line)
    end

    def self.error_from(captures)
      Error.new(captures[:error])
    end

    # Request timed out.
    W_TIMEOUT = /\A
      Request\ (?<timeout>timed\ out)\.
    /x

    # Request timeout for icmp_seq 91
    TIMEOUT = /\A
      (?:(?<packet_received>.*)\ )? # optional `--apple-time` timestamp
      Request\ (?<timeout>timeout)\ for\ icmp_seq\ (?<icmp_seq>\d+)
    /x

    def self.timeout?(line)
      TIMEOUT.match?(line) || W_TIMEOUT.match?(line)
    end

    def self.timeout_from(captures)
      rtt_from(captures) # identical (for now)
    end

    # Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
    W_SUMMARY = /\A
      Packets:
      \ Sent\ =\ (?<transmitted>[0-9]+),
      \ Received\ =\ (?<received>[0-9]+),
      \ Lost\ =\ (?<lost>[0-9]+)
      \ \((?<loss>[0-9.]+%)\ loss\),
    \z/x

    # 197 packets transmitted, 195 packets received, 1.0% packet loss
    SUMMARY = /\A
      (?<transmitted>[0-9]+)\ packets\ transmitted
      ,\ (?<received>[0-9]+)\ packets\ received
      ,\ (?<loss>[0-9.]+%)\ packet\ loss
    \z/x

    def self.summary?(line)
      SUMMARY.match?(line) || W_SUMMARY.match?(line)
    end

    def self.summary_from(captures)
      captures[:transmitted] = captures[:transmitted].commify
      captures[:received] = captures[:received].commify

      Summary.new(captures)
    end

    # Minimum = 42ms, Maximum = 66ms, Average = 53ms
    W_STATS = /\A
      Minimum\ =\ (?<min>[0-9.]+)ms,
      \ Maximum\ =\ (?<max>[0-9.]+)ms,
      \ Average\ =\ (?<avg>[0-9.]+)ms
    \z/x

    # round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms
    STATS = %r{\A
      round-trip\ min/avg/max/stddev\ =
      \ (?<min>[0-9.]+)
      /(?<avg>[0-9.]+)
      /(?<max>[0-9.]+)
      /(?<stddev>[0-9.]+)
      \ ms
    \z}x

    def self.stats?(line)
      STATS.match?(line) || W_STATS.match?(line)
    end

    def self.stats_from(captures)
      captures[:min] = Float(captures[:min])
      captures[:avg] = Float(captures[:avg])
      captures[:max] = Float(captures[:max])

      captures[:stddev] = Float(captures[:stddev]) if captures.include?(:stddev)

      Stats.new(captures)
    end

    # Reply from 8.8.8.8: bytes=32 time=213ms TTL=115
    W_RTT = /\A
      Reply\ from\ (?<ipaddr>.*):\ bytes=(?<packet_size>\d+)\ time=(?<rtt>.*)ms\ TTL=(?<ttl>\d+)
    \z/x

    # 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=18.735 ms
    # 08:33:15.476429 64 bytes from 1.1.1.1: icmp_seq=0 ttl=57 time=42.666 ms
    # 09:03:32.542825 64 bytes from 8.8.8.8: icmp_seq=23868 ttl=54 time=928.529 ms (DUP!)
    RTT = /\A
      (?:(?<packet_received>.*)\ )? # optional `--apple-time` timestamp
      (?<packet_size>\d+)\ bytes
      \ from\ (?<ipaddr>.*):
      \ icmp_seq=(?<icmp_seq>\d+)
      \ ttl=(?<ttl>\d+)
      \ time=(?<rtt>.*)\ ms
      (?:\ (?<duplicate>\(DUP!\)))?
    \z/x

    def self.rtt?(line)
      RTT.match?(line) || W_RTT.match?(line)
    end

    def self.rtt_from(captures)
      Response.new(
        captures[:packet_received],
        captures[:packet_size],
        captures[:ipaddr],
        captures[:icmp_seq],
        captures[:ttl],
        captures[:rtt],
        captures[:duplicate],
        captures[:timeout],
      )
    end

    # 1549101987 1.1.1.1 23.973
    # 1549101987.938 192.168.0.1 42.666
    RRTT = /\A
      (?<packet_received>[0-9.]+)
      \s+
      (?<ipaddr>[0-9.]+)
      \s+
      (?<rtt>[0-9.]+)
    \z/x

    def self.rrtt?(line)
      RRTT.match?(line)
    end

    def self.rrtt_from(captures)
      rtt_from(captures) # identical (for now)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Lint/DuplicateBranch
    def self.process(line)
      objectify = case line.strip
                  when RTT then :rtt_from
                  when W_RTT then :rtt_from
                  when TIMEOUT then :timeout_from
                  when W_TIMEOUT then :timeout_from
                  when ERROR then :error_from
                  when HEADER then :header_from
                  when W_HEADER then :header_from
                  when FOOTER then :footer_from
                  when W_FOOTER then :footer_from
                  when SUMMARY then :summary_from
                  when W_SUMMARY then :summary_from
                  when STATS then :stats_from
                  when W_STATS then :stats_from
                  when RRTT then :rrtt_from
                  end

      return unless objectify # let it rip (need more coverage)

      send(objectify, $LAST_MATCH_INFO.symbolised_named_captures)
    end
    # rubocop:enable Lint/DuplicateBranch
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
