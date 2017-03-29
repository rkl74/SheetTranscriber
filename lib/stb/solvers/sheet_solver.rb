require 'stb/solvers/djikstra_solver'
require 'stb/solvers/guitar_notes_solver'
require 'stb/music/sheet'
require 'stb/util/graph'


class SheetSolver
  def initialize(sheet, guitar)
    @sheet = sheet.dup
    @guitar = guitar.dup
    @gns = GuitarNotesSolver.new(@guitar)
    solve()
  end

  def proposed_solution()
    @proposed_solution
  end

  def graph()
    @graph
  end

  private

  def solve()
    beats_arrangement = solve_each_beat()
    compressed = compress(beats_arrangement)
    solve_states(compressed)
  end

  def solve_each_beat()
    # Rest beat to begin
    solution = [[[]]]
    @sheet.each_beat{|notes|
      # Solve arrangement for active notes by minimizing the cost of fret arragenemnt.
      solutions = @gns.solve(notes)
      solution << solutions
    }
    # Rest beat as last beat
    solution << [[]]
    return solution
  end

  # Minimizes the path of transition costs
  def solve_states(seq)
    # Create nodes for each state in the sequence
    state_nodes = seq.each_with_index.map{|potential_states,i|
      potential_states.each_with_index.map{|state,j|
        Graph::Node.new(state, [i,j].join('_'))
      }
    }

    @graph = Graph.new
    # Add nodes to graph
    state_nodes.each{|state|
      state.each{|node|
        @graph.add_node!(node.name, node)
      }
    }
    # Dense mapping of one time state to the next.
    (state_nodes.length-1).times{|i|
      cur_nodes = state_nodes[i]
      next_nodes = state_nodes[i+1]
      # Create dense mapping of current nodes to next nodes
      cur_nodes.each{|from_node|
        next_nodes.each{|next_node|
          cost = transition_cost(from_node.val, next_node.val)
          @graph.add_directed_edge!(from_node.name, next_node.name, cost)
        }
      }
    }
    return @proposed_solution = DjikstraSolver.new(@graph).path(state_nodes.first[0].name, state_nodes.last[0].name)
  end

  def compress(beats)
    b = beats.dup
    compressed = []
    prev, cur = nil, b.first
    loop do
      break if b.length == 0
      cur = b.shift.sort
      next if cur == prev
      compressed << cur
      prev = cur
    end
    return compressed
  end

  def basic_cost_matrix(from, to)
    costs = from.map{|x1,y1|
      to.map{|x2,y2|
        [(x1-x2).abs,(y1-y2).abs]
      }
    }
    return Matrix.new(costs, from, to)
  end

  # Transition cost of the disjoint elements.
  def transition_cost(cur_arrangement, nxt_arrangement)
    # map old to new
    cur = cur_arrangement - nxt_arrangement
    nxt = nxt_arrangement - cur_arrangement
    
    cost = 0
    case
    when nxt_arrangement.length == 0
      # Cost of transitioning to arrangement with 0 assignments = 0
      cost = 0
    when cur_arrangement.length == 0
      # Cost of transitioning to arrangement from 0 assigements = difficulty of next arrangement
      # Find the average fret (as a best-fit line to compute a cost)
      total = 0
      nxt.each{|_,fret| total += fret}
      avg = (total/(nxt.length * 1.0)).round
      nxt.each{|_,fret| cost += (fret-avg).abs}
    else
      if cur.length < nxt.length
        cur, nxt = nxt, cur
      end
      cost_matrix = basic_cost_matrix(cur, nxt)
      solver = HungarianSolver.new(cost_matrix)
      solution = solver.run()
      solution.each{|x,y| cost += cost_matrix[x][y]}
    end
    return cost
  end

end
