class Object

  def deep_map(&block)
    if self.respond_to? :each_pair
      out = {}
      self.each_pair do |k, v|
        out[k] = v.deep_map(&block)
      end
      return out
    elsif self.respond_to? :each
      out = []
      self.each do |x|
        out << x.deep_map(&block)
      end
      return out
    else
      return block.call(self)
    end
  end

end