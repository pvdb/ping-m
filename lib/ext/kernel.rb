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
    quotient, remainder = (count * 1.0).divmod(8.0)
    quotient, remainder = [max, 0] if max && quotient >= max
    (FULL * quotient) + PARTIALS[remainder.to_i]
  end
  # rubocop:enable Naming/MethodName
end
