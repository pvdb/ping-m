# frozen_string_literal: true

# rubocop:disable Style/OneClassPerFile

class Numeric
  def commify
    to_s.commify
  end
end

class String
  def commify
    # only commify the integer part, never the decimals
    sub(/\A-?\d+/) { |int| int.gsub(/(\d)(?=(\d{3})+\z)/, '\1,') }
  end
end

# rubocop:enable Style/OneClassPerFile
