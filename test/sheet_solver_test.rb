#!/usr/bin/env ruby

require 'bundler/setup'
require 'stb'

data = File.open(File.expand_path(ARGV.shift)).read
guitar = Music::Guitar.new
sheet = Music::MxmlSheet::parse!(data)
solver = SheetSolver.new(sheet, guitar)

#solver.display_recommended
solver.display_sequential_states
