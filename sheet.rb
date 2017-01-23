module Music
	class Sheet
		attr_reader :sequence

		def initialize(sheet)
			parse(sheet)
		end

		def num_beats
			return @sequence.length
		end

		def self.parse(sheet)
			return new(sheet)
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

	end
end