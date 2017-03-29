require 'stb/util/graph'
require 'stb/util/binary_heap'

class DjikstraSolver
  INFINITY = Float::INFINITY
  UNDEFINED = :undefined

  class Distance
    attr_accessor :distance, :to
    def initialize(distance, to)
      @distance = distance
      @to = to
    end

    def <(rhs)
      @distance < rhs.distance
    end

    def <=(rhs)
      @distance <= rhs.distance
    end

    def >(rhs)
      @distance > rhs.distance
    end

    def >=(rhs)
      @distance >= rhs.distance
    end

    def ==(rhs)
      @distane == rhs.distance
    end

    def <=>(rhs)
      @distance <=> rhs.distance
    end
  end

  def initialize(graph)
    @graph = graph
  end

  def path(from, to)
    if !@graph.contains?(from) || !@graph.contains?(to)
      raise ArgumentError, "Nodes not found!"
    end
    distances = self.class.solve(@graph, from)
    return [INFINITY, []] if distances[to][:cost] == INFINITY
    path = []
    cur_node = to
    loop do
      path.unshift([cur_node, @graph.nodes[cur_node].val])
      break if cur_node == from
      cur_node = distances[cur_node][:prev]
    end
    return [distances[to][:cost], path]
  end

  class << self

    def solve(graph, from)
      distances = {}
      # Set all distances to infinity if it's not the source
      graph.nodes.values{|node| distances[node.name] = node.name == from ? 0 : INFINITY}
      unvisited = BinaryHeap.new(:min_heap)

      # initialization
      distances[from] = {prev: nil, cost: 0}
      unvisited.insert!(Distance.new(0, graph.nodes[from]))

      graph.nodes.select{|name,node| name != from}.each{|name,node|
        distances[name] = {prev: nil, cost: INFINITY}
      }

      loop do
        break if unvisited.length == 0
        # Pop  unvisited node with the lowest distance
        d = unvisited.pop!()
        dist, current_node = d.distance, d.to
        # Find tenative distance of current node to its neighbors.
        current_node.edges.each{|cost,node|
          c = distances[current_node.name][:cost] + cost
          # Replace current distance if there exists a shorter path.
          if distances[node.name][:cost] == INFINITY || c < distances[node.name][:cost] 
            distances[node.name] = {prev: current_node.name, cost: c}
            unvisited.insert!(Distance.new(c, node))
          end
        }
       end
      return distances
    end

  end

end
