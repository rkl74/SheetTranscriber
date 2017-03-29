require 'stb/music/notes'

module Music
  class StringInstrument
    attr_accessor :tuning, :min_octave, :max_octave
    attr_reader :nstrings, :tuning_vals
    
    def initialize(tuning, min_oct, max_oct)
      set_octave_range!(min_oct, max_oct)
      set_tuning!(tuning)
    end
    
    def set_octave_range!(min, max)
      raise ArgumentError, "Octaves cannot be negative." if min < 0 || max < 0
      raise ArgumentError, "Error: min > max. Invalid range: [#{min},#{max}]." if min > max
      @min_octave = min
      @max_octave = max
      return
    end
    
    def set_tuning!(tuning)
      raise ArgumentError, "0 string tunings provided!" if tuning.nil? || tuning.length == 0
      @tuning = []
      @tuning = tuning.map{|note| Note.new(note) }
      @nstrings = tuning.length
      return
    end
    
  end
  
end
