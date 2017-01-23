module Music
  class Note
    attr_accessor :note, :octave, :duration
    attr_reader :val, :name
    
    NOTE_TO_INT = {
      '-'  => '00',
      'A'  => '01',
      'A#' => '02', 'Bb' => '02',
      'B'  => '03',
      'C'  => '04',
      'C#' => '05', 'Db' => '05',
      'D'  => '06',
      'D#' => '07', 'Eb' => '07',
      'E'  => '08',
      'F'  => '09',
      'F#' => '10', 'Gb' => '10',
      'G'  => '11',
      'G#' => '12', 'Ab' => '12'
    }
    
    INT_TO_NOTE = {
      0  => '-',
      1  => 'A',
      2  => 'Bb',
      3  => 'B',
      4  => 'C',
      5  => 'C#',
      6  => 'D',
      7  => 'Eb',
      8  => 'E',
      9  => 'F',
      10 => 'F#',
      11 => 'G',
      12 => 'Ab'
    }
    
    def initialize(note)
      parse!(note)
    end
    
    def self.int(i)
      note = i % 100
      oct  = i / 100
      as_str = [oct, note].map{|x| x.to_s}.join(';')
      return new(as_str)
    end
    
    def self.parse(note)
      return new(note)
    end
    
    def val
      return "#{@octave}#{NOTE_TO_INT[@note]}".to_i
    end
    
    def name
      return "#{@note}:#{@octave}"
    end
    
    def num_steps_from(note)
      oct_diff  = (@val / 100) - (note.val / 100)
      note_diff = (@val % 100) - (note.val % 100)
      if note_diff < 0
        oct_diff -= 1
        note_diff += 12
      end
      return oct_diff * 12 + note_diff
    end
    
    def ==(note)
      return val == note.val
    end
    
    def +(integer)
      return sub(integer.abs) if integer < 0
      octave_diff = integer / 12
      note_diff   = integer % 12
      
      new_oct  = (@val / 100) + octave_diff
      new_note = (@val % 100) + note_diff
      
      if new_note > 12
        new_note -= 12
        new_oct += 1
      end
      return Note.new("#{INT_TO_NOTE[new_note]};#{new_oct};#{duration}")
    end
    alias :add :+
    
    def -(integer)
      return add(integer.abs) if integer < 0
      octave_diff = integer / 12
      note_diff   = integer % 12
      
      new_oct  = (@val / 100) - octave_diff
      new_note = (@val % 100) - note_diff
      
      if new_note < 0
        new_note += 12
        new_oct -= 1
      end
      return Note.new("#{INT_TO_NOTE[new_note]};#{new_oct};#{duration}")
    end
    alias :sub :-
    
    private
    
    def parse!(note)
      note, octave, duration = note.split(/;/)
      raise ArgumentError, "Missing note." if note   == ""
      raise ArgumentError, "Unrecognized note: #{@note}." if NOTE_TO_INT[note].nil?
      raise ArgumentError, "Missing octave." if octave == ""
      raise ArgumentError, "Octave cannot be negative." if octave.to_i < 0
      raise ArgumentError, "Duration of note cannot be negative." if duration.to_i < 0
      
      @duration = duration.to_i
      @note     = note
      @octave   = octave.to_i
      return
    end
    
  end
end
