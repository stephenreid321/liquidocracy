class Nomination
  include Mongoid::Document
  include Mongoid::Timestamps
     
  belongs_to :account
  belongs_to :tag
  
  field :tweet_attrs, :type => Hash
  field :nominator, :type => String
  field :nominated, :type => String
  field :nominator_attrs, :type => Hash
  field :nominated_attrs, :type => Hash
  
  validates_uniqueness_of :nominator, :scope => :account, :unless => :tag
  validates_uniqueness_of :nominator, :scope => [:account, :tag], :if => :tag
  validates_presence_of :account, :nominator, :nominated, :nominator_attrs, :nominated_attrs
  
  before_validation :check_no_global_nomination_if_tag
  def check_no_global_nomination_if_tag
    errors.add(:nominated, "You must remove your global nomination before adding tag nominations") if self.tag and (n = Nomination.find_by(nominator: self.nominator, account: self.account, tag: nil)) and (n != self)
  end    
    
  before_validation :check_no_self_nomination
  def check_no_self_nomination
    errors.add(:nominated, "A nominator can't nominate to him/herself") if self.nominator == self.nominated
  end  
                    
  def self.fields_for_index
    [:account_id, :nominator, :nominator_screen_name, :nominated, :nominated_screen_name, :tag_id]
  end
  
  def self.fields_for_form
    {
      :account_id => :lookup,
      :nominator => :text,      
      :nominated => :text,      
      :tag_id => :lookup,      
      :tweet_attrs => :disabled_text_area,
      :nominator_attrs => :disabled_text_area,
      :nominated_attrs => :disabled_text_area      
    }
  end
  
  def summary
    "#{nominator_screen_name} to #{nominated_screen_name}#{" ##{tag.name}" if tag}"
  end
  
  def nominator_screen_name
    nominator_attrs['screen_name']
  end
  
  def nominated_screen_name
    nominated_attrs['screen_name']
  end
  
  def self.lookup
    :summary
  end
   
end
