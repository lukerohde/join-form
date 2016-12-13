
class DateTime
	# Couldn't assign nil to DateTime
	# Copied fix from 3.2.22.5, but I'm stuck on 3.2.13 for SQL2005 support
  def <=>(other)
    if other.kind_of?(Infinity)
      super
    elsif other.respond_to? :to_datetime
      super other.to_datetime
    else
      nil
    end
  end
end