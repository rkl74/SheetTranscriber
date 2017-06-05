#!/usr/bin/env ruby

require 'bundler/setup'
require 'stb/music/mxml_sheet'

data = File.open(File.expand_path(ARGV.shift)).read
sheet = Music::MxmlSheet::parse!(data)
puts sheet.to_s

