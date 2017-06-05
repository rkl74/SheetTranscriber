#!/usr/bin/env ruby

require 'stb/music/guitar'
require 'stb/music/sheet'
require 'stb/solvers/hungarian_solver'
require 'set'

class GuitarNotesSolver

  def initialize(guitar)
    @guitar = guitar.dup
    setup()
  end

  # Returns [guitar_string_name, guitar_string_index, capo_offset]
  # FIXME: If there are two stirngs that are tuned exactly the same are both assigned a note,
  # the solver will not guarantee a permutation of those solutions.
  def solve(notes)
    ############################################
    # Preprocessing
    notes = uniq(notes).sort.select{|n| !n.is_rest?}
    return [[]] if notes.length == 0
    raise ArgumentError, "There are more unique notes than strings!" if notes.length > @guitar.nstrings
    # Separate the notes to be solved into two categories: open notes vs non-open notes
    open_notes = notes.select{|note| @open_notes.key?(note.val)}
    non_open_notes = notes.select{|note| !@open_notes.key?(note.val)}.sort

    # If there are zero non-open notes, then all the notes can be played with no fingers.
    return [open_notes.map{|note| [note.name, @open_notes[note.val].first, 0]}] if non_open_notes.length == 0

    # Note we can arbitrarily choose any note as our point of reference for spatial locality for a given string.
    # However, notes that can utilize open strings may reduce cost but negatively affect the premise of spatial locality of note-string assignment.
    # Therefore, use lowest note that cannot be an open string note to preserve spatial locality.
    # With this, there is no need to choose between an open string or non-open string for a potential open string note.
    base_note = non_open_notes.first
    base_note_task = notes.each_with_index.select{|n,i| n == base_note}.first[1]
    note_offsets = notes.map{|note| note.num_steps_from(base_note)}

    # Initialize basic cost matrix
    cost_matrix = init_cost_matrix(notes)

    if !AssignmentSolver::solvable?(cost_matrix)
      warn [notes.join(","), "is unsolvable"].join(" ")
      return []
    end
    
    ############################################
    # String-Note Optimal Assignment
    # Use as many strings needed from highest (right) to lowest (left)
    solutions = Set.new
    (0..@guitar.nstrings-notes.length).to_a.reverse.each {|from|
      used_strings = @sorted_tuning[from...@guitar.nstrings]
      string_offsets = @offsets_grid[from][from...@guitar.nstrings]
      # Grab the submatrix of partially filled cost_matrix
      base = (from...@guitar.nstrings).map{|r|
        cost_matrix[r]
      }
      
      # Fill in the nil elements of the submatrix with relative offsets
      layer = string_offsets.map{|s_offset| note_offsets.map{|n_offset| (n_offset - s_offset)}}
      layer_abs = layer.map{|row| row.map{|e| e.abs}}

      # Relative positions
      relative_pos = overlay(base, layer)
      # Euclidean distance conversion
      costs = overlay(base, layer_abs)
      costs = Matrix.new(costs, used_strings, notes)
 
      # Compute best assignment solution
      solver = HungarianSolver.new(costs)
      solution = solver.run()
      next if solution.length == 0

      # Find the offset on the string being used as a point of reference for the base_note
      base_str, note_idx = solution.select{|w,t| t == base_note_task}.first
      base_note_offset = base_note.num_steps_from(used_strings[base_str])

      # Adjust relative offsets to center around the designated base note position.
      adjustment = layer[base_str][note_idx] * -1
      layer.each{|row| row.map!{|e| e += adjustment}}

      solution = solution.select{|w,t| layer[w][t]}.map{|w,t|
        relative_offset = layer[w][t]
        # Check if this is an open string note
        offset_from_capo = if base[w][t] == 0
                             # Open note string since base element is 0
                             0
                           else
                             # Compute offset from capo for this string
                             base_note_offset + relative_offset
                           end
        [used_strings[w].name, from+w, offset_from_capo]
      }
      solutions << solution
    }

    return solutions.to_a
  end
  
  private
  
  def setup()
    @open_notes     = {}
    @guitar.adjusted_tuning.each_with_index{|note, i|
      @open_notes[note.val] ||= []
      @open_notes[note.val] << i
    }
    @sorted_tuning  = @guitar.adjusted_tuning.sort
    @offsets_grid   = gridify(@sorted_tuning)
    return
  end

  # Compute offsets for base notes of one string to be played by other strings.
  # Read: row->col (from string->play note offset)
  def gridify(notes)
    return notes.map{|n1|
      notes.map{|n2|
        n2.num_steps_from(n1)
      }
    }
  end

  def uniq(notes)
    return notes.map{|note|
      Music::Note::int(note.val)
    }.uniq
  end

  # Determine if each note can be an open string note and whether it is possible for a given string.
  def init_cost_matrix(notes)
    basic_cost_matrix = @guitar.adjusted_tuning.each_with_index.map {|str_note, i|
      notes.map{|note|
        if str_note == note
          # Open note string
          0
        elsif @guitar.last_fret[i] < note || note < str_note
          # Compared note is impossible on current string if:
          # - lower than lowest note on the string 
          # - higher than the highest note on the string
          AssignmentSolver::IMPOSSIBLE
        else
          nil
        end
      }
    }
    return Matrix.new(basic_cost_matrix, @guitar.adjusted_tuning, notes)
  end

  # Pushes values from layer onto its respective element in base if the base element is nil
  def overlay(base, layer)
    return base.each_with_index.map{|row,r|
      row.each_with_index.map{|e,c|
        e.nil? ? layer[r][c] : e
      }
    }
  end
end

