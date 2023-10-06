# frozen_string_literal: true

module JSON
  module_function def escape(json)
    # https://stackoverflow.com/questions/1250079/
    json.gsub("'", "'\"'\"'")
  end
end
