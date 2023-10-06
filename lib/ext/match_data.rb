# frozen_string_literal: true

class MatchData
  def symbolised_named_captures
    names.to_h { |name| [name.to_sym, self[name]] }
  end
end
