#!/usr/bin/env ruby

require 'bundler/setup'
require 'stb/solvers/guitar_notes_solver'

c_chord = ['C:3', 'E:3', 'G:4'].map{|e| Music::Note.new(e)}
guitar = Music::Guitar.new()
gns = GuitarNotesSolver.new(guitar)

solutions = gns.solve(c_chord)
solutions.each_with_index{|sol,i| p "SOLUTION:#{i}", sol}
