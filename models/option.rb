class Option
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :poll  
   
  field :text, :type => String
  field :slug, :type => String
  
  before_validation :set_slug
  def set_slug
    self.slug = self.text.downcase.gsub(' ','-').gsub(/[^a-z0-9\-]/, '')[0..69] if !self.slug
    # could plausibly try to set a non-unique slug...
  end
  
  has_many :votes, :dependent => :destroy
  
  validates_presence_of :text, :slug, :poll
  validates_uniqueness_of :text, :scope => :poll
  validates_uniqueness_of :slug, :scope => :poll
        
  def self.fields_for_index
    [:poll_id, :slug, :text]
  end
  
  def self.fields_for_form
    {
      :poll_id => :lookup,      
      :text => :text,
      :slug => :disabled_text,
      :votes => :collection
    }
  end
    
  def self.lookup
    :text
  end
  
  def weight
    votes.sum(&:weight)
  end  
     
end
