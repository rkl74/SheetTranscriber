require 'stb/solvers/assignment_solver'

class HungarianSolver < AssignmentSolver

  NONE    = :none
  STARRED = :starred # Pseudo-assigned zero
  PRIMED  = :primed  # Uncovered zero

  def initialize(matrix)
    @cost_matrix = self.class.normalize(matrix.deep_copy)
    @matrix_size = @cost_matrix.nrows

    # Variables for solving the matrix
    unmarked = @matrix_size.times.map{
      @matrix_size.times.map{ NONE }
    }
    @annotated_matrix = Matrix.new(unmarked)
    @preimage = []
    @image = []

    @rows_covered = [false] * matrix.nrows
    @cols_covered = [false] * matrix.ncols
  end
  
  def minimize(workers, task)
  end

  def maximize(workers, task)
  end

  def summary()
    puts "ROWS COVERED:"
    p @rows_covered
    puts "COLS COVERED:"
    p @cols_covered
    puts "ANNOTATED MATRIX:"
    @annotated_matrix.dump()
    puts "COST MATRIX:"
    @cost_matrix.dump()
  end

  def run(labeled = false)
    return [] if !self.class.solvable?(@cost_matrix)
    self.class.reduce_matrix!(@cost_matrix) # Step 1
    star_zeroes!() # Step 2
    step = 3
    while true
      break if step == :done
      case step
      when 3
        step = cover_starred_zeroes!()
      when 4
        step = prime_zeroes!()
      when 5
        step = make_augmenting_path!()
      when 6
        step = augment_path!()
      end
    end
    assignments =  @annotated_matrix.find(STARRED)
    
    if labeled
      assignments.map!{|worker,task|
        [@cost_matrix.rownames[worker], @cost_matrix.colnames[task]]
      }
    end
    return assignments
  end
  
  # Step 2: Assign as many tasks as possible.
  # Indicate this by starring an element
  # When a zero is starred, the corresponding row and column are now eliminated
  # from consideration for assignment.
  def star_zeroes!()
    @matrix_size.times{|r|
      next if @rows_covered[r]
      @matrix_size.times{|c|
        next if @cols_covered[c]
        if @cost_matrix[r][c] == 0
          star!(r,c)
          cover_row!(r)
          cover_col!(c)
          break
        end
      }
    }
    clear_covers!()
  end
  alias_method :step2, :star_zeroes!
  
  # Step 3: Cover each column containing a starred zero
  # If all columns are covered, there is a complete set of unique optimzed assignments.
  def cover_starred_zeroes!()
    num = 0    
    @matrix_size.times{|c|
      if col_has_star?(c)
        cover_col!(c)
        num += 1
      end
    }
    if num >= @matrix_size
      return :done
    else
      return 4
    end
  end
  alias_method :step3, :cover_starred_zeroes!

  # Step 4: Prime uncovered zeroes.
  # If there is no starred zero in the row with the primed zero, go to step 5.
  # If there is a starred zero in the row with the primed zero,
  # cover the row and uncover the column containing the starred zero.
  # Continue until there are no more uncovered zeroes.
  def prime_zeroes!()
    while true
      uncovered_zeroes = find_uncovered_zeroes()
      if uncovered_zeroes.length == 0
        return 6
      end
      
      r_index, c_index = uncovered_zeroes.shift
      prime!(r_index, c_index)
      
      sc_index = @annotated_matrix.find_in_row(r_index, STARRED).first
      if sc_index
        cover_row!(r_index)
        uncover_col!(sc_index)
      else
        @preimage[0] = r_index
        @image[0]    = c_index
        return 5
      end
    end
  end
  alias_method :step4, :prime_zeroes!

  # Step 5: Construct alternating primed and starred zeros.
  # Since this step is taken, there is at least one starred zero
  def make_augmenting_path!()
    # Construct alternating paths
    complete = false
    count = 0
    
    while !complete
      row = @annotated_matrix.find_in_col(@image[count], STARRED).first
      
      if row
        count += 1
        @preimage[count] = row
        @image[count] = @image[count-1]
      else
        complete = true
      end

      if !complete
        col = @annotated_matrix.find_in_row(@preimage[count], PRIMED).first
        count += 1
        @preimage[count] = @preimage[count-1]
        @image[count] = col
      end
    end

    # Modify the paths
    (count+1).times {|i|
      row = @preimage[i]
      col = @image[i]
      
      if starred?(row, col)
        unstar!(row, col)
      else
        star!(row, col)
      end
    }
    clear_covers!()
    clear_primes!()
    return 3
  end
  alias_method :step5, :make_augmenting_path!

  # Step 6: Add the min element to every element of each covered row and
  # subtract from each uncovered column. Return to Step 4 without altering stars, primes, or covered lines.
  def augment_path!()
    # Find smallest uncovered element
    e_min = nil
    @cost_matrix.each_with_index{|row,r|
      next if @rows_covered[r]
      row.each_with_index{|e,c|
        next if @cols_covered[c]
        next if e == IMPOSSIBLE
        e_min ||= e
        e_min = e if e < e_min
      }
    }

    # Add min element to each covered row
    @rows_covered.each_with_index{|status,r|
      next if !status
      @cost_matrix[r].map!{|e| e == IMPOSSIBLE ? IMPOSSIBLE : e + e_min}
    }

    # Subtract min element from each uncovered column
    @cols_covered.each_with_index{|status,c|
      next if status
      @cost_matrix.set_col!(c, @cost_matrix.col(c).map{|e| e == IMPOSSIBLE ? IMPOSSIBLE : e - e_min})
    }
    return 4
  end
  alias_method :step6, :augment_path!

  def find_uncovered_zeroes()
    return @cost_matrix.find(0).select{|r,c| !@rows_covered[r] && !@cols_covered[c]}
  end

  def starred?(r_index, c_index)
    return @annotated_matrix[r_index][c_index] == STARRED
  end
  
  def col_has_star?(c_index)
    return @annotated_matrix.find_in_col(c_index, STARRED).length > 0
  end

  def prime!(r_index, c_index)
    @annotated_matrix[r_index][c_index] = PRIMED
  end

  def clear_primes!()
    @annotated_matrix.map!{|row|
      row.map{|e|
        e == :PRIMED ? NONE : e
      }
    }
  end
  
  def clear_covers!()
    @rows_covered.map!{false}
    @cols_covered.map!{false}
  end
  
  def star!(r_index, c_index)
    @annotated_matrix[r_index][c_index] = STARRED
  end

  def unstar!(r_index, c_index)
    @annotated_matrix[r_index][c_index] = NONE
  end

  def cover_row!(r_index)
    @rows_covered[r_index] = true
  end

  def cover_col!(c_index)
    @cols_covered[c_index] = true
  end

  def uncover_row!(r_index)
    @rows_covered[r_index] = false
  end

  def uncover_col!(c_index)
    @cols_covered[c_index] = false
  end

end
