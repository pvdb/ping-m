# frozen_string_literal: true

module Ping
  class Statistics < OpenStruct
    def initialize(hash = nil)
      super
      @s1 = @s2 = 0.0 # for stddev calcs
    end

    def merge!(other_stats)
      other_stats.each_pair do |member, value|
        next if value.nil?
        raise ArgumentError, 'duplicate value' unless self[member].nil?

        self[member] = value
      end
      self
    end

    def merge(other_stats)
      dup.merge! other_stats
    end

    def update_with(response)
      return if response.timeout?

      self.time = response.packet_sent.to_f

      old_count = count || 0
      new_count = old_count + 1
      self.count = new_count

      self.rtt = response.rtt
      old_avg = avg || 0.0
      new_avg = ((old_avg * old_count) + rtt) / new_count

      self.min = [min, rtt].compact.min
      self.avg = new_avg.round(3)
      self.max = [max, rtt].compact.max

      # https://en.wikipedia.org/wiki/Standard_deviation
      # (taken from section: #Rapid_calculation_methods)
      # rubocop:disable Lint/UselessNumericOperation
      @s1 += rtt**1; @s2 += rtt**2
      # rubocop:enable Lint/UselessNumericOperation
      stddev = Math.sqrt((count * @s2) - (@s1**2)) / count
      self.stddev = stddev.round(3)
    end
  end
end
