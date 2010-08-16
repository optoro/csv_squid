require 'tree_node'

module ToCsv
  # Return a string of comma seperated values corresponding
  # to attributes of the objects stored in array.
  #
  # Objects stored in array are assumed to implement the method
  # attributes().
  #
  # options hash:
  # :only => val, where val is a symbol or array or symbols corresponding
  # to the only attributes to be displayed.
  #
  # :except => val, where val is a symbol or array of symbols corresponding
  # to the attributes you wish to leave out.
  #
  # :methods => val, where val is a symbol or array of symbols corresponding
  # to the names of methods called on each object of the array whos return
  # values will be put into the csv string in addition to normal attribute values.
  #
  # :header => val, where val is either true or false, corresponding to supressing
  # all header information, or leaveing on all header information, respectively.
  # :header => true is the default.
  #
  # :include => val, where val is a symbol, array of symbols, or hash with symbol
  # keys corresponding to associated objects whos attributes should also be
  # appended to the csv string.
  #
  # --------------------
  # Global Csv Options
  # --------------------
  # :headers => true, (default) csv will contain header information at 
  #   beginning of string.
  # :headers => false, csv will leave off header information
  #
  # :column_order => [...] an array of symbols representing column names, and
  #   the order to which they should be listed.
  #
  # :column_names => {:sym1 => "name1", :sym2 => "name2} 
  def make_csv(options = {})
    array = Array(self).flatten
    
    return '' if array.empty?

    # Leave header info on by default.
    options[:headers] = options[:headers].nil? ? true : options[:headers] 

    # Generate a csv object for appending
    output = FasterCSV.generate do |csv|
      
      header = []
      rows = []
      
      array.each do |element|
        # Create tree which holds an attributes_hash corresponding
        # to object attributes.  
        tree = create_tree(element, "", options)
        
        # Rebuild tree with same object labels on each level.
        rebuild(tree)

        if options[:headers]
          header = get_csv_header(tree, options) 
          # Append header information to csv
          csv << header unless header.empty?
          # Only want headers to be displayed once per array item.
          options[:headers] = false
        end

        rows += append_rows(tree, options)

      end # self.each

      # Remove duplicate rows
      rows.uniq!

      # Append each row the csv separately
      rows.each { |row| csv << row }

    end # FasterCSV.generate
    
    output
  end
  alias :to_csv :make_csv
    
  #############################################################################
  # Private Methods
  #############################################################################
  
  private
  
  # Determines every possible path from root to leaves within the tree.
  # Each path uses a depth first traversal.  Attribute information is gathered
  # for each node during the traversal.  Once a leaf is reached, all attribute
  # information is appended to csv as a row.  Then process is repeated starting
  # back at the root and traversing to next leaf in tree.
  def append_rows(tree,options)
    if options[:column_order]
      return append_rows_col_order(tree,options)
    end
    
    # Ordered array with attribute values.  Used as the row to append to csv
    # if options[:column_order] is nil.
    next_row = []

    # Array of arrays which will store row information.  Each level
    # of the result holds a row array to be used later to append to csv.
    result = []

    # Perform depth-first traversal
    tree.each do |node|
      if (node.has_children? == false)
        # Arrived at a leaf node.  Now back trace all the way to root
        # while acquiring attribute values along the way.

        # Go back up tree following parent path.
        while node.parent
          attributes_hash = node.content
          
          # Get sorted array of attribute name symbols.
          keys = attributes_hash.keys.sort{|a,b| a.to_s <=> b.to_s}
          
          # Reverse the order of elements in array.
          keys.reverse!

          keys.each do |key|
            next_row << attributes_hash[key]
          end
          
          # Get parent node
          node = node.parent
        end

        # Now get parent attribute values
        attributes_hash = node.content

        # Get sorted array of attribute name symbols.
        keys = attributes_hash.keys.sort{|a,b| a.to_s <=> b.to_s}

        if node.has_children?
          keys.reverse!
        end

        keys.each do |key|
          next_row << attributes_hash[key]
        end

        # No need to reverse if tree has no children
        if node.has_children?
          next_row.reverse!
        end

        # Store next row
        result << next_row unless next_row.empty?
        
        # Reset next row 
        next_row = []
    
      end #if node.has_chilren?
      
    end #tree.each
    result
  end

  # Appends attribute values to csv based on ordering of columns specified
  # by options[:column_order] array.
  def append_rows_col_order(tree, options)
    # Hash to store unique attribute_keys with their values for each object
    # in the tree.  Used to look up object attribute values for a specific
    # column when options[:column_order] is specified. 
    result_hash = {}

    # Array to hold string values to append as next csv row.
    next_row = []
    
    # Array of arrays which will store row information.  Each level
    # of the result holds a row array to be used later to append to csv.
    result = []
    
    # Array which holds symbol names corresponding to attribute_hash keys
    column_order = options[:column_order]

    # Dept-first traversal through tree
    tree.each do |node|
      if (node.has_children? == false)
        # Arrived at a leaf node.  Now back trace all the way to root
        # while acquiring attribute values along the way.

        # Go back up tree following parent path.
        while node.parent
          attributes_hash = node.content

          # Append all key-value pairs to result_hash
          attributes_hash.each do |key, value|
            result_hash[key] = value 
          end

          node = node.parent
        end

        # Now node is root, so get its attributes. 
        attributes_hash = node.content

        # Append all key-value pairs to result_hash
        attributes_hash.each do |key, value|
          result_hash[key] = value 
        end

        # Build up the next csv row.
        column_order.each do |key|
          next_row << result_hash[key]
        end
      
        # Store array of next row.
        result << next_row unless next_row.empty?
        
        # Reset next row and result_hash 
        next_row = []
        result_hash = {}
     
      end #if node.has_chilren?
    end #tree.each
    result
  end

  # Returns true if each level of tree has the same object_types, or false
  # otherwise.
  def check_tree_levels(tree)
    return true unless tree.has_children?
    
    # For each node in tree compare first_child_type to rest of children's 
    # type and return false upon first non-equal type.
    tree.bft do |node|
      next unless node.has_children?
      
      first_child_type = node.child_array.first.name
     
      # Compare each child's type for a given parent node. 
      node.child_array.each do |child|
        if child.name != first_child_type
          return false
        end
      end
    end

    return true 
  end


    # Rebuild tree so that each level has same object types without destroying
    # parent-child relationships.
  def rebuild(tree)
    return if check_tree_levels(tree)
    
    # Will hold all object types found in tree.
    object_types = []

    # Will hold all nodes at specific levels of the tree.
    tree_levels = []

    # Go through all tree nodes in a depth-first manner
    tree.each do |node|
      type = node.name
      
      if (object_types.include?(type) == false)
        object_types << type 
        
        hash = {type => [node]}
        
        tree_levels << hash
      else
        # Object type already present, so try to append node
        # to specific level.
      
        # Search for hash with key == type
        hash = tree_levels.find { |hash| hash.has_key?(type)}
        
        # Get array of nodes
        node_array = hash[type]

        # Add node to array if it is not already present
        node_array << node unless node_array.include?(node) 
      end
    end

    tree.build_tree(tree_levels, 0)
  end


  # Returns a sorted array of strings representing header information 
  # of tree. 
  def get_csv_header(tree, options)
    result = []

    # Hash which maps attribute keys to user specified column name strings.
    col_names_hash = options[:column_names]

    if options[:column_order]
      col_order_array = options[:column_order]

      result = col_order_array.map do |item|
        if options[:column_names]
          # Get the new
          item = col_names_hash[item]
        else
          item = item.to_s.titleize
        end
      end

      return result
    end
   
    # Dept-first traversal through tree 
    tree.each do |node|
      attributes_hash = node.content 

      # Get array of symbols representing attribute names.   
      attribute_names = attributes_hash.keys

      # Sort the names which are represented as symbols
      attribute_names = attribute_names.sort{ |a,b| a.to_s <=> b.to_s }

      attribute_names.each do |name|
        if col_names_hash
          column = col_names_hash[name]
        else
          column = get_obj_name(name)
        end

        if (result.include?(column) == false)
          result << column
        end
      end

    end #tree.each
    
    result
  end

  # Returns the root of a new tree.  Nodes of the tree will store
  # an atrributes hash corresponding to the attributes and their
  # respective values for <object>. If options contains an :include
  # association then the root node will contain a child node
  # with an attributes hash for the associated object.  
  def create_tree(object, object_label = "", options={})
    # Store hash with symbols as keys representing the names
    # of attributes and strings as values.
    attributes_hash = get_attributes_hash(object, object_label, options)

    #if object_label == ""
    #  object_label = get_obj_label(self.first)
    #end

    # Encapsulate attributes_hash for given object inside a TreeNode.
    node = TreeNode.new(:name => object_label, :content => attributes_hash)

    if options[:include]
      # Create children nodes.

      # include_value could be a symbol, array, hash, or object.
      include_value = options[:include]

      # Store an array of method accessor names / objects
      keys = include_value.respond_to?(:keys) ? \
        include_value.keys : [include_value]
      
      # Flatten array incase include_value is itself an array.
      keys = keys.flatten

      # Sort keys in order to keep output consistent
      keys = keys.sort{ |a,b| a.to_s <=> b.to_s }

      # Loop through each include key
      keys.each do |key|
        # Hash of associated objects and their attribute display options
        associated_hash = get_assoc_objs_hash(object, key, include_value)

        assoc_objs_array = associated_hash[:objects] || []
        associated_options = associated_hash[:options]
       
        if associated_options.nil?
          associated_options = {}
        end

        # Create a child node for each associted_object
        assoc_objs_array.each do |assoc_object|
          # Get object_label symbol of assoc_object
          object_label = get_obj_label(key)
      
          # Append child node to current tree node
          node << create_tree(assoc_object, object_label, associated_options)

        end

      end #keys.each
    end #if options[:include]

    node
  end


  # Returns a hash with symbol keys representing the names of the object's 
  # attributes.  Values for all object attributes are also determined and
  # stored in the returned hash.
  def get_attributes_hash(object, object_label = "", options={})
    # Get attribute_names, sort them, and store them as symbols in an array.
    attribute_names = object.attributes.keys.sort.map(&:to_sym)

    # Keep attribute_names we need, and remove the ones we don't.
    if options[:only]
      attribute_names = attribute_names & Array(options[:only])
    else
      attribute_names = attribute_names - Array(options[:except])
    end

    # Tack on method names to attribute array
    attribute_names += Array(options[:methods])

    # Convert attribute_names array into hash with nil values
    attributes_hash = {}

    # Fill in hash with keys corresponding to attribute_names.
    # Set values to nil.
    attribute_names.each do |item|
      attributes_hash[item] = nil 
    end

    # Store object values within attributes_hash
    attributes_hash.each do |key, value|
      if (object.respond_to?(key))
        
        extended_key = key

        if (object_label == "")
          # Dealing with primary object within array, so leave
          # off object_label.
          attributes_hash[extended_key] = object.send(key)
        else
          # Dealing with no primary object, so tack on object_label
          # to attribute keys.
          extended_key = "#{object_label.to_s}_#{key.to_s}".to_sym
          
          attributes_hash[extended_key] = object.send(key)

          attributes_hash.delete(key)
        end

      end 
    end

    attributes_hash
  end
  

  # Returns a hash containing an array of associated objects of _caller
  # and their attribute display options
  def get_assoc_objs_hash(_caller, key, value)
    if key.is_a?(Symbol)
      if _caller.respond_to?(key)
        # Then key is the name of an accessor method which returns an 
        # associated object or an array of objects.
        assoc_objs_array = Array(_caller.send(key)).flatten
      end
    else
      # key is an object by itself
      assoc_objs_array = Array(key).flatten
    end

    # Determin if assocaited object has any options
    value.is_a?(Hash) ? options = value[key] : options = {}

    associated_hash = {:objects => assoc_objs_array, :options => options}
  end

  # Returns a titlized string representing the name of <obj>
  # in singular form.  
  def get_obj_name(obj)
    if obj.is_a?(Symbol)   
      return obj.to_s.singularize.titleize
    elsif obj.is_a?(Array)
      return obj.first.class.to_s.titleize
    else
      return obj.class.to_s.titleize 
    end
  end

  # Returns an underscore symbol representation
  # of obj.
  def get_obj_label(obj)
    label = get_obj_name(obj)
    label.downcase.gsub(" ","_").to_sym
  end

end #end module ToCsv

class Array
  include ToCsv
  def to_csv(options={})
    make_csv(options)
  end
end

class ActiveRecord::Base
  include ToCsv
end



