# frozen_string_literal: true

module Kernel
  # reference: https://en.wikipedia.org/wiki/Block_Elements
  # PARTIALS = ['', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']

  PARTIALS = [
    '',
    "\u258F",
    "\u258E",
    "\u258D",
    "\u258C",
    "\u258B",
    "\u258A",
    "\u2589",
    "\u2588",
  ].freeze

  FULL = PARTIALS.last

  # rubocop:disable Naming/MethodName
  def Blocks(count, max = nil)
    if RUBY_PLATFORM =~ /mingw|mswin/i
      # temporary workaround until we figure out how
      # to correctly use UTF-8 characters on Windows
      '#' * (count * 1.0 / 8.0)
    else
      quotient, remainder = (count * 1.0).divmod(8.0)
      quotient, remainder = [max, 0] if max && quotient >= max
      (FULL * quotient) + PARTIALS[remainder.to_i]
    end
  end
  # rubocop:enable Naming/MethodName
end
