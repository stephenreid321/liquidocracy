class Tag
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  
  has_many :tagships, :dependent => :destroy
  has_many :nominations, :dependent => :destroy
  
  validates_presence_of :name
    
  def self.fields_for_index
    [:name]
  end
  
  def self.fields_for_form
    {
      :name => :text,
      :tagships => :collection,
      :nominations => :collection
    }
  end
  
  def self.lookup
    :name
  end
  
end
