class OntologyWrapper 

  attr_accessor :displayLabel
  attr_accessor :id
  attr_accessor :ontologyId
  attr_accessor :userId
  attr_accessor :parentId
  attr_accessor :format
  attr_accessor :versionNumber
  attr_accessor :internalVersion
  attr_accessor :versionStatus
  attr_accessor :isCurrent
  attr_accessor :isRemote
  attr_accessor :isReviewed
  attr_accessor :statusId
  attr_accessor :dateReleased
  attr_accessor :contactName
  attr_accessor :contactEmail
  attr_accessor :isFoundry
  attr_accessor :isManual
  attr_accessor :filePath
  attr_accessor :urn
  attr_accessor :homepage
  attr_accessor :documentation
  attr_accessor :publication
  attr_accessor :dateCreated
  
  attr_accessor :versions
  attr_accessor :project_count
  attr_accessor :review_count
  
  FILTERS={
  "All"=>0,
  "OBO Foundry"=>1,
  "UMLS"=>2,
  "WHO" =>3,
  "HL7"=>4
  
  }
  
  STATUS={
    "Waiting For Parsing"=>1,
    "Parsing"=>2,
    "Ready"=>3,
    "Error"=>4,
    "Not Applicable"=>5
  }
  
  FORMAT=["OBO","OWL-DL","OWL-FULL","OWL-LITE","PROTEGE","LEXGRID_XML"]
    
  
  def from_params(params)
    self.displayLabel = params[:displayLabel]   
    self.id= params[:id]   
    self.ontologyId= params[:ontologyId]   
    self.userId= params[:userId]   
    self.parentId= params[:parentId]   
    self.format= params[:format]   
    self.versionNumber= params[:versionNumber]   
    self.internalVersion= params[:internalVersion]   
    self.versionStatus= params[:versionStatus]   
    self.isCurrent= params[:isCurrent]   
    self.isRemote= params[:isRemote]   
    self.isReviewed= params[:isReviewed]   
    self.statusId= params[:statusId]   
    self.dateReleased= params[:dateReleased]   
    self.contactName= params[:contactName]   
    self.contactEmail= params[:contactEmail]   
    self.isFoundry= params[:isFoundry]   
    self.filePath= params[:filePath]   
    self.urn= params[:urn]   
    self.homepage= params[:homepage]   
    self.documentation= params[:documentation]   
    self.publication= params[:publication]  
    self.isManual = params[:isManual] 
  end
  
  def map_count
    count = Mapping.find(:all,:conditions=>{:source_ont=>self.ontologyId}).size
  end
  
  def reviews
    if self.review_count.nil?
      self.review_count = Review.count(:conditions=>{:ontology_id=>self.ontologyId})
    end
    return self.review_count
  end
  
  def projects
    if self.project_count.nil?
      self.project_count = Project.count(:conditions=>"uses.ontology_id = '#{self.ontologyId}'",:include=>:uses)
    end
    return self.project_count
  end
 
  def to_param    
     "#{id}"
  end
  
  def topLevelNodes
       DataAccess.getTopLevelNodes(self.id)     
  end
end