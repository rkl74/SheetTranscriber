require 'crack'
require 'json'
require 'stb/music/sheet'
require 'stb/util/gcd'
require '~/bin/LL'

module Music
  class MxmlSheet < Music::Sheet
    include XMath
    attr_accessor :additional_info

    TIED_NOTE_ERR = 'There exists an active tied note without an end.'

    class << self
      def parse!(str)
        sheet = self.new("")
        sheet.additional_info = {}
        data = Crack::XML::parse(str)

        # Process score_partwise hash
        sp_hash = data['score_partwise']
        # Dump non-measure info into additional_info
        sp_hash.each{|k,v|
          if k != 'part'
            sheet.additional_info[k] = v
          end
        }

        # Process part(s).
        parts = sp_hash['part']

        # Quarter notes are 'divided'. Default # of divisions is 1.
        # E.g. 1 part -> 1 division = quarter note.
        #      2 part -> 1 division = 8th note.
        #      3 part -> 1 division = 12th note
        attributes = {
          divisions: 1.0
        }
        
        # Track state
        # Assumptions made about state:
        state = {
          t: 0,
          prev_t_unit: 0,
          active_notes: {},
          x: nil
        }
        seq = {}
        parts['measure'].each{|measure|
          # Check if we need to update attributes
          update_attributes!(attributes, measure)
          
          # process notes in measure
          notes = input_handler(measure['note'])
          notes.each {|n|              
            t_unit = n['duration'].to_i / attributes[:divisions]
            note_str = get_note_str(n)
            
            if note_str[0] == Music::Note::REST_NOTE || n['default_x'].to_f != state[:x]
              # Calculate new point of reference
              state[:t] += state[:prev_t_unit]
              state[:prev_t_unit] = t_unit
              state[:x] = n['default_x'].to_f
            end
            
            # Check for tied notes
            if state[:active_notes].key?(note_str)
              state[:active_notes][note_str] += t_unit
              if n['notations'] && n['notations']['tied']
                case
                when n['notations']['tied']['start']
                  next
                when n['notations']['tied']['stop']
                  seq[state[:t]] ||= []
                  seq[state[:t]] << Music::SheetNote.new(note_str, state[:active_notes][note_str])
                else
                  raise ArgumentError, TIED_NOTE_ERR
                end
              end
            else
              if n['notations'] && n['notations']['tied'] && n['notations']['tied']['start']
                state[:active_notes][note_str] = t_unit
              else
                seq[state[:t]] ||= []
                seq[state[:t]] << Music::SheetNote.new(note_str, t_unit)
              end
            end
          }
        }
        
        step = XMath::gcd_of_arr(seq.keys[1..-1])
        cur = 0.0
        stop = seq.keys.last
        sheet.sequence = []

        # Use steps standardize the beat
        loop do
          break if cur > stop
          notes = seq[cur]
          notes ||= []
          sheet.sequence << notes
          cur += step
        end

        sheet
      end
     
      private
      def get_note_str(note_hash)
        note, pitch, octave = if note_hash['pitch']
                                [
                                 note_hash['pitch']['step'],
                                 case note_hash['pitch']['alter'].to_i
                                 when 1
                                   '#'
                                 when -1
                                   'b'
                                 else
                                   nil
                                 end,
                                 note_hash['pitch']['octave']
                                ]
                              else # rest notes
                                ['-',nil,0]
                              end
        
        note_str = [[note, pitch].join, octave].join(":")
      end
      
      def update_attributes!(attributes, measure)
        # Check if metadata about measures/notes changed.
        if measure['attributes']
          # Ex:
          # {
          #   "attributes": {
          #     "divisions": "8",
          #     "key": {
          #       "fifths": "2"
          #     },
          #     "time": {
          #       "beats": "4",
          #       "beat_type": "4"
          #     },
          #     "clef": {
          #       "sign": "F",
          #       "line": "4"
          #     },
          #     "measure_style": {
          #       "multiple_rest": "4"
          #     }
          #   }
          # }                
          
          # Update relative note length changes
          if measure['attributes']['divisons']
            attributes[:divisions] = measure['attributes']['divisions'].to_i * 1.0
          end
        end
      end

      # Sometimes the mxml sheet represents certain fields as hash for single elements
      # or an array of hashes for multiple elements. Normalize these fields.
      def input_handler(input)
        processed = case 
                    when input.class == Hash
                      [ input ]
                    when input.class == Array
                      input
                    else
                      raise ArgumentError, "Unrecognized input class: #{input.class}"
                    end
      end
    end

  end
end
