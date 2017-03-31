#!/usr/bin/env ruby

require 'bundler/setup'
require 'stb/solvers/guitar_notes_solver'

problems  = []
problems << ['C:3', 'E:3', 'G:4']
problems << ['A:3', 'E:4', 'E:3', 'A:4']

problems.each{|notes|
  p notes
  c_chord = notes.map{|e| Music::Note.new(e)}
  guitar = Music::Guitar.new()
  gns = GuitarNotesSolver.new(guitar)
  
  solutions = gns.solve(c_chord)
  solutions.each_with_index{|sol,i|
    p "SOLUTION:#{i}", sol
    puts guitar.display(sol.map{|str_info, fret| [str_info[1], fret]})
    p sol.map{|str_info, fret| (Music::Note.new(str_info[0])+fret).name}
  }
}
