module Music
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

    private

    def parse(sheet)
      @sequence = []
      sheet.split(/\|/).each {|bt|
        beat = []
        bt.split(/,/).each {|note|
          note.strip!
          beat << Node.new(note)
        }
        @sequence << beat
      }
    end

    def each_beat()
    end
    
  end
end
