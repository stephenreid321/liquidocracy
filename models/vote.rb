class Vote
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :poll
  belongs_to :option
  
  field :tweet_attrs, :type => Hash
  field :user_id, :type => String
  
  validates_presence_of :user_id, :poll, :option
  validates_uniqueness_of :user_id, :scope => :poll, :case_sensitive => false
  
  before_validation :set_dependent_fields
  def set_dependent_fields
    self.poll = self.option.poll
  end  
  
  before_validation :check_for_delegation  
  def check_for_delegation
    errors.add(:poll, "You've already delegated your vote for this poll") if poll.delegations.find_by(delegator: /^#{user_id}$/i)
  end   
        
  before_validation :check_poll_not_closed
  def check_poll_not_closed
    errors.add(:poll, "That poll is closed") if poll.closed?
  end    
          
  def self.fields_for_index
    [:poll_id, :option_id, :user_id]
  end
  
  def self.fields_for_form
    {
      :poll_id => :lookup,
      :option_id => :lookup,
      :user_id => :text,
      :tweet_attrs => :disabled_text_area
    }
  end
    
  def self.lookup
    :user_id
  end
  
  def weight
    dt = Delegation.tree(poll, user_id)
    dt ? dt.flatten.count+1 : 1
  end  
    
end
