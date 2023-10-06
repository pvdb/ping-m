# frozen_string_literal: true

class OpenStruct
  def to_json(*args)
    to_h.to_json(args)
  end
end
