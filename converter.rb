#!/usr/bin/env ruby

require './guitar'
require './sheet'

class Matrix
  attr_accessor :matrix, :colnames, :rownames

  def initialize(matrix, colnames = [], rownames = [])
    @matrix = matrix
    @colnames = colnames
    @rownames = rownames
  end

  def col(c)
    return matrix.map{|row| row[c]}
  end

  def row(r)
    return matrix[r]
  end

  def set_col(c, vals)
    if col(c).length != vals.length
      raise ArgumentError, 'Input column is not of equal length'
    end
    matrix.map!{|row|
      row[i] = vals[i]
      row
    }
  end

  def set_row(r, vals)
    if row(r).length != vals.length
      raise ArgumentError, 'Input row is not of equal length'
    end
    matrix[r] = vals
  end

  def ncols()
    return matrix.first.length
  end

  def nrows()
    return matrix.length
  end
end

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
          matrix.set_row(updated)
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
    # Initialize basic cost matrix
    cost_matrix = basic_cost_matrix()

    possible = solve_required!(basic_cost_matrix)
    return [] if !possible

    ############################################
    # Optimization

    # Compute input notes' offsets
    # Lowest non-open string note
    lowest_note = notes.select{|note| !open_string_notes.key?(note.val)}.first
    
    # All notes are open notes
    if lowest_note.nil?
      return 
    end
    n_offsets   = notes.map{|e, i| e.num_steps_from(lowest_note)}

    solutions = []

    ############################################
    # String-Note Assignment
    @grid_offsets.length.times.to_a.reverse.each {|y|
      start = y
      stop  = @s_offsets.length
      # Start by looking at the highest s strings for assigning n notes such that s >= n.
      next if stop - start < notes.length

      # Compute possible assignment solution
      str_offsets = @grid_offsets[y][start...stop]
      solution = assign(str_offsets, n_offsets, open_string_notes)

      # Verify that this solution is physically possible
      solutions << solution if solution
    }
    return solutions
  end
  
  def assign(s_offsets, n_offsets)
    ############################################
    # Preprocessing
    
    # Ensure it is an n x n grid
    # Create 'empty' notes to be assigned to strings
    if s_offsets.length > n_offsets.length
      n_offsets = [nil] * (s_offsets.length - n_offsets.length) + n_offsets
    elsif n_offsets.length > s_offsets.length
      raise ArgumentError, "There cannot be more notes than strings to be assigned"
    end

    # Compute relative fret cost of assigning strings to notes
    offsets = s_offsets.each_with_index.to_a.map{|s_offset, s|
      n_offsets.map{|n_offset|
        if n_offset.nil?
          nil
        else
          n_offset - s_offset
        end
      }
    }

    # Compute cost of assigning string to notes
    distances = offsets.map{|row|
      row.map {|e| e.to_i.abs}
    }
    # Adjusted cost of strings by zeroing with min distance for a given note
    min_at = []
    distances.length.times {|i| min_at << distances.map{|e| e[i]}.min }
    distances.map {|costs| costs.each_with_index.to_a.map{|e, i| e - min_at[i]} }
    
    ############################################
    # Assignment
    
    
  end

  def optimize(cost_matrix)
    reduced_matrix = reduce_cost_matrix(cost_matrix)

    
  end

  def reduce_cost_matrix(cost_matrix)
    row_reduce = lambda{|matrix|
      return matrix.map {|row|
        row_min = row.min
        row.map{|e| e - row_min}
      }
    }
    return row_reduce.call(row_reduce.call(cost_matrix).transpose)
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
    req.map!{|idx, str|
      [matrix_obj.colnames()[idx], str]
    }
    return req
  end

end
