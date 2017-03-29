class BinaryHeap
  def initialize(type)
    @heap = []
    if type == :min_heap || type == :max_heap
      @type = type
    else
      raise ArgumentError, "Unrecognized heap type"
    end
  end

  def dump()
    p @heap
  end

  def length()
    return @heap.length
  end

  def compare(parent, child)
    case @type
    when :min_heap
      return parent > child
    when :max_heap
      return parent < child
    end
  end

  def insert!(val)
    @heap << val
    child = @heap.length-1
    loop do
      break if child == 0 # root node
      parent = (child / 2.0).ceil - 1
      if compare(@heap[parent], @heap[child])
        # percholate up
        @heap[parent], @heap[child] = @heap[child], @heap[parent]
      else
        break
      end
      child = parent
    end
    return
  end

  def head()
    return @heap[0]
  end

  def pop!()
    return nil if @heap.length == 0
    t = @heap[0]
    @heap[0] = @heap.last
    @heap.pop
    
    parent = 0

    # percholate down
    loop do
      children = @heap[parent*2+1..(parent+1)*2].to_a
      break if children.length == 0

      idx = parent*2+1
      unless children.length == 1
        case @type
        when :min_heap
          idx = @heap[parent*2+1] <= @heap[parent*2+2] ? parent*2+1 : parent*2+2
          break if @heap[parent] <= @heap[idx]
        when :max_heap
          idx = @heap[parent*2+1] >= @heap[parent*2+2] ? parent*2+1 : parent*2+2
          break if @heap[parent] >= @heap[idx]
        end
      end
      @heap[parent], @heap[idx] = @heap[idx], @heap[parent]
      parent = idx
    end
    return t
  end
end
