class TreeNode
  attr_accessor :name
  attr_accessor :id
  attr_accessor :children 
  attr_accessor :ontology_name
  attr_accessor :child_size
  attr_accessor :note_icon
  attr_accessor :map_icon
  
  
  
  def initialize(object=nil)
      unless object.nil?
        self.id = object.id
        initialize_node(object)
      end
  end

  def initialize_node(node_object)
    self.name= node_object.name
    self.child_size = node_object.child_size
    self.ontology_name = node_object.ontology_name   
    if node_object.note_count >0
      self.note_icon = true
    end
    if node_object.mapping_count >0
      self.map_icon = true
    end
    unless node_object.children.empty?
      self.set_children(node_object.children)
    end
  end

  
  def set_children(node_list)
    self.children =[]
    unless node_list.nil?
      for node in node_list
        puts node.inspect
        self.children << TreeNode.new(node)
      end
    end
  end
    
   def expanded
     if !children.nil? && children.length>0
      return true
     else
      return false      
     end
   end
   def to_s
     "Node_Name: #{self.name}  Node_ID: #{self.id}"
   end
  
end