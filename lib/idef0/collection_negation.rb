# TODO: Why doesn't using include/extend work here?

module Enumerable
  def -@
    map(&:-@)
  end
end
