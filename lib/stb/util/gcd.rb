module XMath
  def self.gcd(a, b)
    raise ZeroDivisionError, "Divide by 0 error." if a.to_f == 0.0 || b.to_f == 0.0
    return gcd(b,a) if a > b
    if (b % a).to_f == 0.0
      return a
    else
      return gcd(a, b % a)
    end
  end

  def self.gcd_of_arr(arr)
    case
    when arr.length == 0
      return nil
    when arr.length <= 2
      return gcd(arr.first, arr.last)
    else
      d = arr[0]
      arr.each{|e|
        d = gcd(d, e)
      }
      return d
    end
  end

end

