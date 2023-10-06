# frozen_string_literal: true

class MatchData
  def symbolised_named_captures
    names.each_with_object({}) { |name, captures|
      captures[name.to_sym] = self[name]
    }
  end
end
