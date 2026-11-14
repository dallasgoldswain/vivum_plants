# One location's numbers for an item (D157): saleable and unavailable on hand, what's held,
# and what's available to sell (saleable − held).
Stock::Position = Data.define(:location, :saleable, :unavailable, :held) do
  def self.sum(positions)
    new(nil, positions.sum(&:saleable), positions.sum(&:unavailable), positions.sum(&:held))
  end

  def on_hand = saleable + unavailable
  def available = [ saleable - held, 0 ].max
end
