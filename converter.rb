require './guitar'
require './sheet'

class Solver
  def initialize(guitar, sheet)
		@guitar = guitar
    @sheet  = sheet
    
    preprocess()
    
  end
  
  def solve(notes)
    ############################################
    # preprocess to reduce search space
    uniq_notes = uniq(notes)
		adjusted_tuning = {}
    open_str_notes = {}
    unused_strings = {}
    
    # separate into open string notes and unused strings
    @guitar.adjusted_tuning.each_with_index{|note, i|
      adjusted_tuning[note.val] = i
      # Note that don't require a finger but use a string
      if uniq_notes.include?(note)
        open_str_notes[i] = note
      else
        unused_string[i] = []
      end
    }
    uniq_notes.delete_if {|note| !adjusted_tuning[note.val]}
    
    # If there are more than 4 notes that require a string, bar required.
    bar_flag = uniq_notes.length > 4
    
    #############################################
    # fret pattern recognition
    note_grid      = gridify(uniq_notes)
    note_distances = grid_to_hash(grid)
    
    # find notes that are on the same fret
    shared_dist = @distances.dup.keep_if {|k, v| note_distances.key?(k)}
    
    shared_distance.values.each {|v|
      v.each{|from, to|
        
      }
    }		
    
  end
  
  private
  
  def uniq(notes)
    return notes.map{|note|
      Music::Note::int(note.val)
    }.uniq.sort{|x, y| x.val <=> y.val}
  end
  
  def preprocess()
    @grid      = gridify(@guitar.tuning)
    @distances = grid_to_hash(@grid)
    # determine distance between strings from left -> right for adjacent pairs
    @pattern = []
    (@guitar.tuning.length-1).times{|i|
      @pattern << @guitar.map[i+1].num_steps_from(@guitar.tuning[i])
    }
  end
  
  # grid of from->to distances
  def gridify(notes)
    grid = []
    notes.length.times {|i|
      grid << notes.map {|note|
        note.num_steps_from(notes[i])
      }
    }
    return grid
  end
  
  def grid_to_hash(grid)
    distances = []
    grid.each_with_index {|row, from|
      row.each_with_index {|dist, to|
        distances[dist] ||= []
        distances[dist] << [from, to]
      }
    }
    return distances
  end
  
=begin  
  # sort strings by lowest note
  four_frets = sliding_window().sort{|x, y| x.first.val <=> y.first.val}
  lowest = four_frets.first.first
  
  @pattern = four_frets.map!{|str|
    str.map{|note|
      note.num_steps_from(lowest)
    }
  }
end
=end

# old stuff
  def fret_window(from, to)
    from = [[0, from].max, @guitar.nfrets].min
    to   = [0, [to, @guitar.nfrets].min].max
    return (from - to).times.map {|offset|
      @guitar.adjusted_tuning.map {|note|
        note + offset
      }
    }
  end
  
  def finger_pos(notes)
    arrangement = []
    uniq_notes = uniq(notes)
    lowest = uniq_notes.first
    frets_for(lowest).each{|str, fret|
      w = fret_window(fret-3, fret+3)
    }
  end
  
  def finger_position(notes)
    strings = [nil] * @guitar.nstrings
    str = []
    # uniq the input notes
    uniq_notes = notes.map{|note|
      Music::Note::int(note.val)
    }.uniq
    # determine notes on each string
    uniq_notes.each{|note|
      @guitar.frets_for(note).each {|s, offset|
        str[s] ||= []
        str[s] << [offset, note]
      }
    }
    # sort note on each string by its offset
    str.map!{|o| o.sort{|x, y| x.first <=> y.first}}
    # sort strings b
  end
end

file = ARGV[0]

sheet  = Music::Sheet.new(File.read(file))
guitar = Music::Guitar.new()
solver = Solver.new(guitar, sheet)
