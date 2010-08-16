#require 'thread'

class TreeNode
  attr_accessor :name, :content, :parent, :enqueued
  attr_reader :child_array
  
  def initialize(params = {})
    params.each {|key,value| self.send("#{key}=", value)}
    @child_array = []
    self 
  end

  # Make node a child of calling Node.
  def <<(node)
    @child_array.push(node)
    node.parent = self
  end

  def remove_children
    @child_array = []
  end

  def has_children?
    return !@child_array.empty?
  end

  # Prints out structure of tree.
  # :name => true, (default) to print out name field for each node.
  # :content => true, to print out content field for each node.
  #
  # For a tree of the given form
  #                A1
  #               /  \ 
  #             B1    B2
  #             /\    /\
  #           C1 C2  C3 C4
  #
  # output would be:
  # +A1
  # |  +B1
  # |  |  +C1
  # |  |  +C2
  # |  +B2
  # |  |  +C3
  # |  |  +C4
  def printTree(options = {})
    # Set defaults
    options[:name] ||= true
    options[:content] ||= false
    
    result = ""
  
    options[:output] = result 
    # Traverse tree and modify result by tacking on child names.
    printTraversal(options)
    
    puts result
  end

  def printTraversal(options={})
    output = options[:output]
    
    # If name is nil, try to find a name
    # field within content hash    
    if @content.is_a?(Hash)
      if @content[:name] && @name.nil?
        @name = @content[:name]
      end
    end

    if options[:name] && options[:content]
      output << "+#{@name}:#{@content}"
    elsif options[:name]
      output << "+#{@name}"
    elsif options[:content]
      output << "+#{@content}"
    end

    if options[:tabs]
      tabs = options[:tabs]
    else
      tabs = 0
    end

    @child_array.each do |child|
      tabs += 1

      if child.is_a?(TreeNode)
        output << "\n"
          
        tabs.times{output << "|  "}
        
        options[:output] = output
        options[:tabs] = tabs

        child.printTraversal(options)
        
        # Done printing chilren, so decrement tabs
        tabs -= 1   
      end
    end
  end

  # Traverse tree in a depth-first, left-to-right manner, yielding
  # node to block upon discovery of node. 
  def each(&block)
    block.call(self)
    @child_array.each do |node|
      node.each(&block)
    end
  end

  # Breadth First Traversal.
  # Traverse tree in a breadth-first, left-to-rigth manner, yielding
  # node to block upon discovery of node.
  def bft(&block)
    queue = Queue.new
  
    # Set all nodes to not enqueued
    self.each do |node|
      node.enqueued = false
    end

    queue.push(self) 
    self.enqueued = true

    while(queue.size > 0)
      # Get next node in the queue
      node = queue.pop
      
      # Pass node off to block
      block.call(node)

      # Enqueue all children nodes
      node.child_array.each do |child|
        if !child.enqueued
          queue.push(child)
          child.enqueued = true
        end
      end

    end #while
  end
  
  # Creates a tree out of nodes in levels_array
  # with root at start_index.
  #
  # Example:
  # root = TreeNode.new(:name => "Avi")
  # cs = TreeNode.new(:name => "CS")
  # cs101 = TreeNode.new(:name => "CS101")
  # eng101 = TreeNode.new(:name => "ENG101")
  # ipa = TreeNode.new(:name => "IPA")
  # hawiian = TreeNode.new(:name => "Hawiian")
  #
  # levels_array = [{:student => [root]}, 
  #                {:major => [cs]},
  #                {:course => [cs101, eng101]},
  #                {:favorite => [ipa, hawiian]}]
  # build_tree(levels_array, 0) 
  #
  # Creates tree with the following strucute:
  # +Avi
  # |  +CS
  # |  |  +CS101
  # |  |  |  +IPA
  # |  |  |  +Hawiian
  # |  |  +ENG101
  # |  |  |  +IPA
  # |  |  |  +Hawiian
  def build_tree(levels_array, start_index)
    while levels_array[start_index + 1]
      node_hash = levels_array[start_index]

      # Get array of all parent nodes on current tree level
      parent_array = node_hash.values.flatten 

      parent_index = 0
      prev_parent = nil

      while parent_array[parent_index]
        parent = parent_array[parent_index]
       
        parent.remove_children
       
        # Get the array of children nodes
        child_array = levels_array[start_index + 1].values.flatten

        child_array.each do |child|
          # Check to see if child has recently been added to a parent
          # within this method.  If so we need to clone the child.
          if prev_parent == child.parent
            # Append shallow copy of child 
            parent << child.clone
          else
            parent << child
          end
        end
        prev_parent = parent
        parent_index += 1
      end
      start_index += 1
    end
  end

  def list_parents(options={})
    # Set default options
    options[:name] ||= true
    options[:content] ||= true

    self.each do |node|
      if (options[:name] == true)
        print "#{node.name}"
      end

      if (options[:content] == true)
        print "#{node.content}" 
      end

      if node.parent
        print ", parent: "
        if options[:name]
          print "#{node.parent.name}"
        end

        if options[:content]
          print "#{node.parent.content}"
        end
      end
      
      print "\n"
    end
    nil
  end

end # class TreeNode


############################################################################### 
# Usuage
############################################################################### 

#root = TreeNode.new(:name => "Root")
#child = TreeNode.new(:name => "Child")

#root = TreeNode.new(:name => "A1")
#b1 = TreeNode.new(:name => "B1")
#b2 = TreeNode.new(:name => "B2")
#b3 = TreeNode.new(:name => "B3")

#root << b1
#root << b2
#root << b3

#c1 = TreeNode.new(:name => "C1")
#c2 = TreeNode.new(:name => "C2")
#c3 = TreeNode.new(:name => "C3")
#c4 = TreeNode.new(:name => "C4")
#c5 = TreeNode.new(:name => "C5")

#b1 << c1
#b1 << c2

#b2 << c3

#b3 << c4
#b3 << c5

#root.printTree
#root.list_parents

