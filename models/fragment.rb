class Fragment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, :type => String
  field :body, :type => String  
  
  validates_presence_of :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /[a-z0-9\-]+/
    
  def self.fields_for_index
    [:slug, :body]
  end
  
  def self.fields_for_form
    {
      :slug => :text,
      :body => :text_area
    }
  end
  
end
