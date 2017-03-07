#!/usr/bin/env ruby

require './guitar'
require './sheet'
require './matrix'

class Solver
  IMPOSSIBLE = "impossible"

  def initialize(guitar, sheet)
    @guitar = guitar
    @sheet  = sheet

    preprocess()
  end

  # Determine if each note can be an open string note and whether it is possible for a given string.
  def basic_cost_matrix(notes)
    basic_cost_matrix = @guitar.adjusted_tuning.each_with_index.to_a.map {|str_note, i|
      notes.map{|note|
        if str_note == note
          # Open note string
          0
        elsif @guitar.last_fret[i] < note || note < str_note
          # Compared note is impossible on current string if:
          # - lower than lowest note on the string 
          # - higher than the highest note on the string
          IMPOSSIBLE
        else
          nil
        end
      }
    }
    return Matrix.new(basic_cost_matrix, notes, @guitar.adjusted_tuning)
  end

  # Brute-force sudoku-like logic to narrow down must haves positions for certain notes.
  def solve_required!(matrix_obj)
    solvable = true
    complete = false
    matrix = matrix_obj.matrix
    ncols = matrix_obj.ncols
    while true && solvable && !complete
      ncols.each{|note|
        # Determine if there are any usable string positions for this note.
        note_possibilities = matrix.col(note).each_with_index.to_a.select{|cost, str| cost.to_s != IMPOSSIBLE }

        case note_possibilites
        when 0 # Unsolvable
          solvable = false
          break
        when 1 # Only one string assignment for this note
          # update matrix and start from beginning
          usable_string = note_possibilities.first[1]
          prev = matrix.row(usable_string)
          updated = prev.each_with_index.to_a.map{|cost, i|
            if i != note
              IMPOSSIBLE
            else
              cost
            end
          }
          matrix.set_row!(updated)
          # Start from the beginning again to verify there's no change
          break
        end
        
        # If we arrive here, we examined everything and it is at least possible
        # without any physical restrictions.
        if note == (ncols-1)
          complete = true
        end
      }
    end
    
    return solvable
  end

  # Check if a given matrix. Examine if it is impossible solely on the enum IMPOSSIBLE
  def solvable?(matrix)
    solvable = true
    matrix.length.times.each{|i|
      note_possibilities = matrix.col(i).select{|cost| cost.to_s != IMPOSSIBLE }
      if note_possibilites.length == 0
        solvable = false
        break
      end
    }
    return solvable
  end

  def solve(notes)
    ############################################
    # Preprocessing
    notes  = uniq(notes).sort{|x, y| x.val <=> y.val}
    # Find open string notes
    open_notes = notes.select{|note| @open_notes.key?(note.val)}
    non_open_notes = notes.select{|note| !@open_notes.key?(note.val)}

    # Note we can arbitrarily choose any note as our point of reference for spatial locality for a given string.
    # However, notes that can utilize open strings may reduce cost but negatively affect the premise of spatial locality of note-string assignment.
    # Therefore, use lowest note that cannot be an open string note to preserve spatial locality.
    # With this, there is no need to choose between an open string or non-open string for a potential open string note.
    note_offsets = notes.map{|note| note.num_steps_from(non_open_notes.first)}

    # Initialize basic cost matrix
    cost_matrix = basic_cost_matrix(notes)

    # Solve the strings thave only have 1 possible location
    possible = solve_required!(cost_matrix)
    return [] if !possible

    ############################################
    # Cost Optimization
    # Sort by required strings's relative position from left (0) to right (length-1)
    required_strings = req_strings(cost_matrix).sort{|x, y| x[1][:index] <=> y[1][:index]}

    # For whichever of the following is leftmost, use that string as the starting point:
    # - leftmost required string
    # - leftmost string to meet minimum strings for input notes
    leftmost = [required_strings.first[1][:index], @guitar.nstrings - notes.length].min

    ############################################
    # String-Note Assignment
    solutions = []
    while leftmost >= 0
      lower, upper = leftmost, @guitar.nstrings
      submatrix = (lower...uppper).map{|r|
        cost_matrix.row(r)
      }
      submatrix = Matrix.new(submatrix, notes, @guitar.adjusted_tuning[lower...upper])
      str_offsets  = @grid_offsts[lower][lower...upper]

      # Compute possible assignment solution
      solution = assign(str_offsets, note_offsets, submatrix)
      solutions << solution if solution.length > 0
    end

    return solutions
  end
  
  def assign(s_offsets, n_offsets, base_cost_matrix)
    ############################################
    # Preprocessing
    bcm = base_cost_matrix.dup
    matrix = bcm.matrix

    ############################################
    # Fill in the blanks
    s_offsets.each_with_index{|s_offset, s|
      n_offsets.each_with_index{|n_offset, n|
        # Skip already filled in costs
        next if !matrix[s][n].nil?
        matrix[s][n] = n_offset - s_offset
      }
    }
    
    ############################################
    # Ensure it is an n x n grid
    empty_notes_added = s_offsets.length - n_offsets.length
    # Create 'empty' notes to be assigned to strings
    if s_offsets.length > n_offsets.length
      # Add columns of 0 as an empty note
      costs = matrix.map{|row|
        [0] * empty_notes_added + row
      }
    elsif n_offsets.length > s_offsets.length
      raise ArgumentError, "There cannot be more notes than strings to be assigned"
    end

    ############################################
    # Offset distance adjustment
    # Note: The sign of the offset tells us relative location.
    #   This is something that may be useful for consideration.
    adj_cost = costs.map {|row|
      row.map {|e|
        if e.to_s != IMPOSSIBLE
          e.to_i.abs
        else
          e
        end
      }
    }
    ############################################
    # Matrix cost reduction/manipulation O(n^3)
    adj_cost = Matrix.new(adj_cost)
    reduce_cost_matrix(adj_cost)
    count = 0
    while true
      # Upper bound is size of matrix
      return [] if adj_cost.length == count
      count += 1
      break if zero_reduce!(adj_cost)
    end

    ############################################
    # Assignment
  end

  def optimal_assignment(matrix)
    solution = []
    t = matrix.matrix.map{|row| row.map{|e| [e, false]}}
    n = m.length
    rows = {}
    cols = {}
    t.each_with_index {|row, r|
      row.each_with_index {|e, c|
        if e[0] == 0
          rows[r] ||= []
          rows[r] << c
          cols[c] ||= []
          cols[c] << r
        end
      }
    }
    # Select rows and cols that only have one zero
    solution += (rows.select{|r, c| c.length == 1}.map{|r, c| [r, c.first]} + cols.select{|c, r| r.length == 1}.map{|c, r| [r.first, c]}).uniq
    solution.each{|r,c| t[r].map!{|e,x| [e, true]}}
    t = t.transpose
    solution.each{|r,c| t[c].map{|e,x| [e, true]}}
    t = t.transpose

    
  end
  
  private

  def preprocess()
    @open_notes     = {}
    @guitar.adjusted_tuning.each_with_index{|note, i|
      @open_notes[note.val] ||= []
      @open_notes[note.val] << i
    }
    @grid_offsets   = gridify(@guitar.adjusted_tuning.sort{|x,y| x.val <=> y.val})
    @distances      = to_hash(@grid_offsets)
    return
  end

  ############################################
  # helpers
  def uniq(notes)
    return notes.map{|note|
      Music::Note::int(note.val)
    }.uniq
  end

  # Compute offsets for base notes of one string to be played by other strings.
  # Read: row->col (from string->play note offset)
  def gridify(notes)
    grid = []
    notes.length.times{|i|
      grid << notes.map {|note|
        note.num_steps_from(notes[i])
      }
    }
    return grid
  end

  def to_hash(grid)
    distances = []
    grid.each_with_index {|row, from|
      row.each_with_index {|dist, to|
        distances[dist] ||= []
        distances[dist] << [from, to]
      }
    }
    return distances
  end

  # Return a list of notes with its required string
  def req_strings(matrix_obj)
    req = []
    matrix = matrix_obj.matrix
    matrix.ncols.times {|note|
      note_possibilities = matrix.col(note).each_with_index.to_a.select{|cost, str| cost.to_s != IMPOSSIBLE }
      if note_possibilities.length == 1
        req << note_possibilities.first
      end
    }
    req.map!{|note, str|
      [matrix_obj.colnames()[note], {base_string_note: matrix_obj.rowname()[str], index: str}]
    }
    return req
  end

  def reduce_cost_matrix!(matrix)
    adj_cost = matrix.matrix
    reduce = lambda {|m|
      return m.map! {|row|
        min_e = row.select{|e| e.to_s != IMPOSSIBLE}.min
        row.map{|e|
          if e.to_s == IMPOSSIBLE
            IMPOSSIBLE
          else
            e - min_e
          end
        }
      }
    }
    adj_cost = reduce.call(adj_cost)
    adj_cost = reduce.call(adj_cost.transpose).transpose
    return
  end

  def zero_reduce!(matrix)
    m = matrix.matrix
    t = m.map{|row| row.map{|e| [e, false]}}
    rows = {}
    cols = {}
    # Cross out zeroes on row
    m.each_with_index{|row, r|
      row.each_with_index{|e, c|
        if m[r][c] == 0
          rows[r] ||= []
          rows[r] << c
        end
      }
    }
    # srow = rows.select{|k,v| v.length < 2}
    rows.delete_if{|r,cols| cols.length < 2}
    rows.keys.each {|r| t[r].map!{|e,v| [e, true]}}

    # Cross out zeroes on cols
    m.each_with_index{|row, r|
      next if rows[r]
      row.each_with_index{|e, c|
        if m[r][c] == 0
          cols[c] ||= []
          cols[c] << r
        end
      }
    }
    t = t.transpose
    cols.keys.each{|c| t[c].map!{|e,v| [e, true]} }
    t = t.transpose

    optimal_solution = rows.length + cols.length == m.length
    # Not optimal solution
    if !optimal_solution
      e_min = nil
      t.each{|row|
        row.each{|e, v|
          if !v
            e_min ||= e
            e_min = e if e < e_min
          end
        }
      }
      # Subtract min uncovered elemented for each uncovered row
      t.length.times{|r|
        next if rows[r]
        t[r].map!{|e, v| [e-e_min, v]}
      }
      # Add min covered element on each covered column
      t = t.transpose
      cols.keys.each{|c| t[c].map!{|e,v| [e+e_min, v]}}
      t = t.transpose
    end
    matrix.matrix = t.map{|row| row.map{|e,v| e}}
    return optimal_solution
  end
end
