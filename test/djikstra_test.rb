#!/usr/bin/env ruby

require 'bundler/setup'
require 'stb/solvers/djikstra_solver'

graph = Graph.new
[1,2,3,4,5,6].each{|v| graph.add_node!(v, Graph::Node.new(v, v))}

graph.add_undirected_edge!(1,2,7)
graph.add_undirected_edge!(1,3,9)
graph.add_undirected_edge!(1,6,14)
graph.add_undirected_edge!(2,3,10)
graph.add_undirected_edge!(2,4,15)
graph.add_undirected_edge!(3,4,11)
graph.add_undirected_edge!(3,6,2)
graph.add_undirected_edge!(4,5,6)
graph.add_undirected_edge!(5,6,9)

solver = DjikstraSolver.new(graph)

puts "ANSWER: 7"
to = STDIN.gets.strip.to_i
dist, path = solver.path(1,to)
puts dist
p path
