# frozen_string_literal: true

module Ping
  class Processor
    def initialize(monitor)
      @monitor = monitor
    end

    def process(_response)
      raise 'SubclassResponsibility'
    end
  end

  class ConsoleProcessor < Processor
    def process(response)
      # print a coloured version of the
      # round trip data to the console!
      IO.console.puts(response.to_tty(RAINBOW))
    end
  end

  class CaptureProcessor < Processor
    def process(response)
      # inside a Unix pipeline, also write
      # non-coloured version into the pipe
      $stdout.puts(response) # unless $stdout.tty?
    end
  end

  class DebugProcessor < Processor
    def process(_response)
      # inside a Unix pipeline, also write
      # the processed ping input lines
      last_line = @monitor.last_line_processed
      $stdout.puts(last_line) if last_line
    end
  end

  class StatsProcessor < Processor
    def process(_response)
      # inside a Unix pipeline, also write
      # "running stats" into the pipe
      $stdout.puts(@monitor.latest_stats.to_json) # unless $stdout.tty?
    end
  end

  class NotifyProcessor < Processor
    OPTIONS = [
      '-sender ping-m',
      '-title "round trip outlier"',
      '-subtitle "%<subtitle>s"',
      '-message "%<message>s"',
    ].join(' ').freeze

    def process(response)
      return unless response.outlier?

      options = {
        subtitle: response.speed,
        message: <<~"EOMSG".chomp
          round trip to #{response.ipaddr} took #{response.rtt}ms
          (at #{response.packet_sent})
        EOMSG
      }

      `terminal-notifier #{format(OPTIONS, options)}`
    end
  end
end
