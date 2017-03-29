class Graph
  class Node
    attr_accessor :val, :name, :edges

    def initialize(val = nil, name = nil)
      @val = val
      @name = name
      @edges = []
    end

    def add_edge!(cost, node)
      @edges << [cost, node]
      return
    end

    def del_edge!(cost, node_name)
      @edges.delete_if{|c, node| c == cost && node.name == node_name}
    end
    
    def del_edges_to!(node_name)
      @edges.delete_if{|node| node.name == node_name}
    end
    
  end

  attr_accessor :nodes

  def initialize()
    @nodes = {}
  end

  def add_directed_edge!(from_uid, to_uid, cost)
    # Note: There may be several costs for the same source and destination of an edge.
    @nodes[from_uid].add_edge!(cost, @nodes[to_uid])
    return
  end

  def add_undirected_edge!(a, b, cost)
    add_directed_edge!(a, b, cost)
    add_directed_edge!(b, a, cost)
  end

  def del_directed_edge!(from_uid, to_uid, cost)
    @nodes[from_uid].del_edge!(cost, @nodes[to_uid])
    return
  end

  def del_undirected_edge!(a, b, cost)
    del_directed_edge!(a, b, cost)
    del_directed_edge!(b, a, cost)
  end

  def contains?(node_name)
    return @nodes.key?(node_name)
  end

  def add_node!(name, node)
    if contains?(name)
      raise ArgumentError, "Node already exists!"
    end
    @nodes[name] = node
    return
  end

  def del_node!(node_name)
    if !contains?(node_name)
      warn "No matching nodes found!"
    else
      @nodes.delete_if{|uid, _| uid == node_name}
      @nodes.values.each{|node| node.del_edges_to!(node_name)}
    end
    return
  end

end
