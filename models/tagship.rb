class Tagship
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :poll
  belongs_to :tag
  
  validates_presence_of :poll, :tag
  
  attr_accessor :name
  
  before_validation :set_tag
  def set_tag
    self.tag = Tag.find_or_create_by(name: name)
  end
  
  def name
    @name || tag.name
  end
    
  def self.fields_for_index
    [:poll_id, :tag_id]
  end
  
  def self.fields_for_form
    {
      :poll_id => :lookup,
      :tag_id => :lookup
    }
  end
  
  def self.lookup
    :summary
  end
  
  def summary
    "#{poll.question} ##{tag.name}"
  end
   
  
end
