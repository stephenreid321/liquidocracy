class BlogPost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :slug, :type => String
  field :body, :type => String  
  
  validates_presence_of :title, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /[a-z0-9\-]+/
      
  def self.fields_for_index
    [:title, :slug, :body]
  end
  
  def self.fields_for_form
    {
      :title => :text,
      :slug => :slug,
      :body => :text_area
    }
  end
       
end
