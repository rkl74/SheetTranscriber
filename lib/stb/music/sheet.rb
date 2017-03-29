require 'stb/music/note'

module Music
  class SheetNote < Note
    attr_accessor :duration

    def initialize(note, duration)
      super(note)
      raise ArgumentError, "Duration of a note cannot be negative." if duration < 0
      @duration = duration
    end

    def dup()
      return self.class.new(name(), @duration)
    end

  end

  class Sheet
    attr_reader :sequence
    
    class << self
      def parse(sheet)
        return new(sheet)
      end
    end

    def initialize(sheet)
      parse(sheet)
    end
    
    def num_beats
      return @sequence.length
    end

    def dump()
      each_beat{|bt| p bt}
    end

    def each_beat()
      active = []
      @sequence.each{|new_notes|
        # Decrement each active note.
        active.each{|note| note.duration -= 1}
        active.delete_if{|note| note.duration == 0}
        # Dup to prevent changes in duration of sheet notes
        active.concat(new_notes.map{|note| note.dup})
        # Dup to prevent changes of block being yielded to
        yield(active.map{|note| note.dup})
      }
    end

    private

    def parse(sheet)
      @sequence = []
      sheet.split(/\|/).each {|bt|
        beat = []
        bt.split(/,/).each {|note|
          note.strip!
          n, o, d = note.split(/:/)
          beat << SheetNote.new([n,o].join(':'), d.to_i)
        }
        @sequence << beat
      }
    end
    
  end
end
