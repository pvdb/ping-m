# frozen_string_literal: true

class OpenStruct
  def to_json(*)
    to_h.to_json(*)
  end
end
