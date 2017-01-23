require './instruments'

module Music
	class Guitar < StringInstrument
		attr_accessor :nfrets
		attr_reader :nfrets, :capo, :tuning, :adjusted_tuning

	def initialize(nfrets = 24, tuning = ['E;2', 'A;3', 'D;3', 'G;3', 'B;4', 'E;4'], min_oct = 2, max_oct = 6)
		super(tuning, min_oct_max_oct)
		@nfrets = nfrets
		@capo = 0
		set_capo!(@capo)
	end

	def set_capo!(fret)
		fret = 0 if fret < 0
		fret = @nfrets if fret > @nfrets
		@capo = fret
		@adjusted_tuning = @tuning.map {|snote| snote + capo }
		return
	end

	def frets_for(note)
		pos = []
		@adjusted_tuning.each_with_index{|base, i|
			diff = note.num_steps_from(base)
			pos << [i, diff] if diff >= 0 && diff <= @nfrets - capo
		}
		return pos
	end

end