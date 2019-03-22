module Ping
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
  class Parser
    # PING example.com (93.184.216.34): 56 data bytes
    HEADER = /\A
      PING\ (?<hostname>.+)\ \((?<ipaddr>.+)\):\ (?<size>\d+)\ data\ bytes
    \z/x.freeze

    def self.header?(line)
      HEADER.match?(line)
    end

    def self.header_from(captures)
      Header.new(captures)
    end

    # --- example.com ping statistics ---
    FOOTER = /\A
      ---\ (?<hostname>.+)\ ping\ statistics\ ---
    \z/x.freeze

    def self.footer?(line)
      FOOTER.match?(line)
    end

    def self.footer_from(captures)
      Footer.new(captures)
    end

    # ping: sendto: No route to host
    ERROR = /\A
      ping:\ (?<error>.+)
    \z/x.freeze

    def self.error?(line)
      ERROR.match?(line)
    end

    def self.error_from(captures)
      Error.new(captures[:error])
    end

    # Request timeout for icmp_seq 91
    TIMEOUT = /\A
      Request\ (?<timeout>timeout)\ for\ icmp_seq\ (?<icmp_seq>\d+)
    /x.freeze

    def self.timeout?(line)
      TIMEOUT.match?(line)
    end

    def self.timeout_from(captures)
      rtt_from(captures) # identical (for now)
    end

    # 197 packets transmitted, 195 packets received, 1.0% packet loss
    SUMMARY = /\A
      (?<transmitted>[0-9]+)\ packets\ transmitted
      ,\ (?<received>[0-9]+)\ packets\ received
      ,\ (?<loss>[0-9.]+%)\ packet\ loss
    \z/x.freeze

    def self.summary?(line)
      SUMMARY.match?(line)
    end

    def self.summary_from(captures)
      captures[:transmitted] = captures[:transmitted].commify
      captures[:received] = captures[:received].commify

      Summary.new(captures)
    end

    # round-trip min/avg/max/stddev = 35.437/64.677/107.174/24.588 ms
    STATS = %r{\A
      round-trip\ min/avg/max/stddev\ =
      \ (?<min>[0-9.]+)
      /(?<avg>[0-9.]+)
      /(?<max>[0-9.]+)
      /(?<stddev>[0-9.]+)
      \ ms
    \z}x.freeze

    def self.stats?(line)
      STATS.match?(line)
    end

    def self.stats_from(captures)
      captures[:min] = Float(captures[:min])
      captures[:avg] = Float(captures[:avg])
      captures[:max] = Float(captures[:max])
      captures[:stddev] = Float(captures[:stddev])

      Stats.new(captures)
    end

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
    \z/x.freeze

    def self.rtt?(line)
      RTT.match?(line)
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
    \z/x.freeze

    def self.rrtt?(line)
      RRTT.match?(line)
    end

    def self.rrtt_from(captures)
      rtt_from(captures) # identical (for now)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def self.process(line)
      objectify = case line
                  when RTT then :rtt_from
                  when TIMEOUT then :timeout_from
                  when ERROR then :error_from
                  when HEADER then :header_from
                  when FOOTER then :footer_from
                  when SUMMARY then :summary_from
                  when STATS then :stats_from
                  when RRTT then :rrtt_from
                  end

      send(objectify, $LAST_MATCH_INFO.symbolised_named_captures)
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
