require 'stb/util/matrix'

# workers are located on row
# assignments are located on cols

class AssignmentSolver
  WORKERS_ERR = "Not enough workers for the amounts of tasks to be assigned."

  IMPOSSIBLE = :impossible

  class << self
    def normalize(cost_matrix)
      ncols = cost_matrix.ncols
      nrows = cost_matrix.nrows
      
      matrix_size = [ncols,nrows].max

      namer = lambda {|l, reference, prefix|
        return l.times.map{|i|
          if !reference[i].nil?
            reference[i]
          else
            [prefix, i].join('-')
          end
        }
      }
      worker_names = namer.call(matrix_size, cost_matrix.rownames, 'worker')
      task_names   = namer.call(matrix_size, cost_matrix.colnames, 'task')

      diff = ncols - nrows

      if diff == 0
        m = cost_matrix.deep_copy
        m.rownames = worker_names
        m.colnames = task_names
        return m
      elsif diff > 0
        raise ArgumentError, WORKERS_ERR
      else
        diff *= -1
        normalized_matrix = cost_matrix.map{|row| row + [0]*diff}
        return Matrix.new(normalized_matrix, worker_names, task_names)
      end
    end

    # Check if a given matrix is solvable solely based on enum IMPOSSIBLE assignment
    def solvable?(cost_matrix)
      cost_matrix.ncols.times.each{|c|
        if cost_matrix.col(c).select{|cost| cost != IMPOSSIBLE}.length == 0
          return false
        end
      }
      return true
    end

    def reduce_rows!(cost_matrix)
      cost_matrix.map!{|row|
        min_e = row.select{|e| e != IMPOSSIBLE && !e.nil?}.min
        row.map{|e| e == IMPOSSIBLE || e.nil? ? e : e-min_e}
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
