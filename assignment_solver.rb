require './matrix'

# workers are located on row
# assignments are located on cols

class AssignmentSolver

  IMPOSSIBLE = :impossible

  class << self
    # Check if a given matrix is solvable solely based on enum IMPOSSIBLE assignment
    def solvable?(cost_matrix)
      cost_matrix.length.times.each{|i|
        if cost_matrix.col(i).select{|cost| cost != IMPOSSIBLE}.length == 0
          return false
        end
      }
      return true
    end

    def reduce_rows!(cost_matrix)
      cost_matrix.map!{|row|
        min_e = row.select{|e| e != IMPOSSIBLE}.min
        row.map{|e| e == IMPOSSIBLE ? IMPOSSIBLE : e-min_e}
      }
    end
    
    def reduce_cols!(cost_matrix)
      cost_matrix.transpose!
      reduce_rows!(cost_matrix)
      cost_matrix.transpose!
    end
    
    def reduce_matrix!(cost_matrix)
      reduce_rows!(cost_matrix)
      reduce_cols!(cost_matrix)
    end

  end

end
