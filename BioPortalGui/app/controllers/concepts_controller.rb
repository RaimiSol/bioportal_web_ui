class ConceptsController < ApplicationController
  # GET /concepts
  # GET /concepts.xml
   
  layout 'ontology'

  # GET /concepts/1
  # GET /concepts/1.xml
  def show
    time = Time.now
    puts "Starting Retrieval"
    @concept =  DataAccess.getNode(params[:ontology],params[:id])
    puts "Finished in #{Time.now- time}"
      #@concept_id = params[:id] # Removed to see if even used
    
      @ontology = DataAccess.getOntology(params[:ontology])
    if request.xhr?    
      show_ajax_request # process an ajax call
    else
      show_uri_request # process a full call
      render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
    end
  end
  
  def virtual
    time = Time.now
    puts "Starting Retrieval"
    @ontology = DataAccess.getLatestOntology(params[:ontology])
    @concept =  DataAccess.getNode(@ontology.id,params[:id])
    puts "Finished in #{Time.now- time}"
      #@concept_id = params[:id] # Removed to see if even used
    
    if request.xhr?    
      show_ajax_request # process an ajax call
    else
      show_uri_request # process a full call
      render :file=> '/ontologies/visualize',:use_full_path =>true, :layout=>'ontology' # done this way to share a view
    end
  end
  

  def exhibit
      time = Time.now
       puts "Starting Retrieval"
       @concept =  DataAccess.getNode(params[:ontology],params[:id])
       puts "Finished in #{Time.now- time}"

       string =""
       string <<"{
           \"items\" : [\n

       	{\n
       \"title\": \"#{@concept.name}\" , \n
       \"label\": \"#{@concept.id}\" \n"
       for property in @concept.properties.keys
         if @concept.properties[property].empty?
           next
         end
         
           string << " , "
         
           string << "\"#{property.gsub(":","")}\" : \"#{@concept.properties[property]}\"\n"
           
       end

       if @concept.children.length > 0
         string << "} , \n"
       else
         string <<"}"
       end


       for child in @concept.children
         string <<"{
         \"title\" : \"#{child.name}\" , \n
         \"label\": \"#{child.id}\"  \n"
         for property in child.properties.keys
           if child.properties[property].empty?
             next
           end

           string << " , "
           
             string << "\"#{property.gsub(":","")}\" : \"#{child.properties[property]}\"\n"
         end
         if child.eql?(@concept.children.last)
           string << "}"
          else
            string << "} , "
         end
       end

        response.headers['Content-Type'] = "text/html" 
        
       	string<< "]}"







       render :text=> string


   end


  
  # PRIVATE -----------------------------------------
  private
  
  def show_ajax_request
     case params[:callback]
        when 'load' # Load pulls in all the details of a node
          time = Time.now
          gather_details
          puts "Finished Details in #{Time.now - time}"
          render :partial => 'load'
        when 'children' # Children is called only for drawing the tree
          @children =[]
          for child in @concept.children
            @children << TreeNode.new(child)
          end
          render :partial => 'childNodes'
      end    
  end
  
  def show_uri_request # gathers the full set of data for a node
    gather_details
    build_tree

  end
  
  def gather_details  #gathers the information for a node
    
 #    sids = [] #stores the thread IDs
    
  #  sids << spawn(:method => :thread) do  #threaded implementation to improve performance
      #builds the mapping tab
      @mappings = Mapping.find(:all, :conditions=>{:source_ont => @concept.ontology_id, :source_id => @concept.id})    
      
      #builds the margin note tab
      @margin_notes = MarginNote.find(:all,:conditions=>{:ontology_version_id => @concept.version_id, :concept_id => @concept.id,:parent_id =>nil})
      #needed to prepopulate the margin note
      @margin_note = MarginNote.new
      @margin_note.concept_id = @concept.id
      @margin_note.ontology_version_id = @concept.version_id
   # end   
      
   
    
     # for demo only
     @software=[]
     if @ontology.displayLabel.eql?("Biomedical Resource Ontology")
        @software = NcbcSoftware.find(:all,:conditions=>{:ontology_label=>@concept.id})        
      end
    
    
    #wait(sids) #waits for threads to finish
    
    update_tab(@ontology,@concept.id) #updates the 'history' tab with the current node
    
  end
  
  def build_tree
    #find path to root    
    rootNode = @concept.path_to_root
    @root = TreeNode.new()
    @root.set_children(rootNode.children)
    
  end
 
  
end