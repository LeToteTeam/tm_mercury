defprotocol TM.Mercury.ReadPlan do
  @type antennas :: [(number | {number, number})]

  @spec weight(t) :: non_neg_integer
  def weight(rp)

  @spec antennas(t) :: antennas
  def antennas(rp)

  @spec filter(t) :: binary
  def filter(rp)

  @spec protocol(t) :: atom
  def protocol(rp)

  @spec tag_op(t) :: atom
  def tag_op(rp)

  @spec fast_search(t) :: boolean
  def fast_search(rp)

  @spec autonomous_read(t) :: boolean
  def autonomous_read(rp)
end
