class NilClass
  def dup
    self
  end
end

class Symbol
  def dup
    self
  end
end

class Integer
  def dup
    self
  end
end

class Matrix
  attr_accessor :matrix, :colnames, :rownames

  class << self
    def create_matrix(num_rows = 1, num_cols = 1)
      if num_rows <= 0 || num_cols <= 0
        return Matrix.new([[]])
      else
        return Matrix.new(num_rows.times.map{ [nil]*num_cols })
      end
    end
  end

  def initialize(matrix, rownames = [], colnames = [])
    raise ArgumentError, "Rows are not of equal length!" if matrix.map{|row| row.length}.uniq.length > 1
    @matrix = matrix.map{|row| row.map{|e| e.dup}}
    @colnames = colnames.map{|e| e.dup}
    @rownames = rownames.map{|e| e.dup}
  end

  def clone()
    m = nrows.times.length.map{|r| col(r)}
    return Matrix.new(m, @colnames, @rownames)
  end

  def transpose()
    return Matrix.new(@matrix.transpose, @colnames, @rownames)
  end

  def transpose!()
    @matrix = @matrix.transpose
  end

  def ncols()
    return matrix.first.length
  end

  def nrows()
    return matrix.length
  end
  
  ##################################################
  # Deep copy to element level
  def deep_copy
    return Matrix.new(
                      @matrix.map{|row| row.map{|e| e.dup}},
                      @rownames.map{|e| e.dup},
                      @colnames.map{|e| e.dup}
                      )
  end

  def col(c)
    return matrix.map{|row| row[c].dup}
  end

  # Deep copy to element level
  def row(r)
    return matrix[r].map{|e| e.dup}
  end

  ##################################################
  # Setter/Getters
  def [](r)
    return @matrix[r]
  end

  def []=(r, new_row)
    if new_row.length != @matrix.first.length
      raise ArgumentError, "Input row is not of equal length"
    end
    # Add 'empty' rows
    if r >= @matrix.length
      (@matrix.length..r).each{|r_index|
        @matrix[r_index] = [nil] * @matrix.first.length
      }
    end
    @matrix[r] = new_row
  end
  alias_method :set_row!, :[]=

  def set_col!(c, vals)
    if @matrix.length != vals.length
      raise ArgumentError, "Input column is not of equal length"
    end
    # Add 'empty' cols
    matrix.each_with_index{|row,r|
      if c >= @matrix.first.length
        (@matrix.first.length..c).each{|c_index|
          row[c_index] = nil
        }
      end
      row[c] = vals[r]
    }
    return
  end

  ##################################################
  # Iterators
  def each
    @matrix.each{|row|
      yield(row)
    }
  end

  def each_with_index
    @matrix.each_with_index{|row,i|
      yield(row,i)
    }
  end

  def map
    m = @matrix.map{|row|
      yield(row)
    }
  end

  def map!
    @matrix.map!{|row|
      yield(row)
    }
  end

  ##################################################
  # Search
  def find_in_row(r, val)
    found = []
    row(r).each_with_index{|e,c| found << c if e == val}
    return found
  end

  def find_in_col(c, val)
    found = []
    col(c).each_with_index{|e,r| found << r if e == val}
    return found
  end
  
  def find(val)
    found = []
    @matrix.each_with_index{|row,r|
      row.each_with_index{|e,c|
        found << [r,c] if e == val
      }
    }
    return found
  end

  ##################################################
  # Output
  def print(rows = false, cols = false)
  end

  def dump()
    @matrix.each{|row| p row}
    puts '-' * 50
  end
end
