class Delegation
  include Mongoid::Document
  include Mongoid::Timestamps
   
  belongs_to :poll
  
  field :tweet_attrs, :type => Hash
  field :delegator, :type => String
  field :delegated, :type => String
  field :delegator_attrs, :type => Hash
  field :delegated_attrs, :type => Hash
  
  validates_uniqueness_of :delegator, :scope => :poll
  validates_presence_of :poll, :delegator, :delegated, :delegator_attrs, :delegated_attrs
     
  before_validation :check_no_self_delegation
  def check_no_self_delegation
    errors.add(:delegated, "A delegator can't delegate to him/herself") if self.delegator == self.delegated
  end
  
  before_validation :check_for_vote
  def check_for_vote
    errors.add(:poll, "You've already voted on this poll") if poll.votes.find_by(user_id: /^#{delegator}$/i)
  end
              
  def self.fields_for_index
    [:poll_id, :delegator, :delegator_screen_name, :delegated, :delegated_screen_name]
  end
  
  def self.fields_for_form
    {
      :poll_id => :lookup,
      :delegator => :text,
      :delegated => :text,
      :tweet_attrs => :disabled_text_area,
      :delegator_attrs => :disabled_text_area,      
      :delegated_attrs => :disabled_text_area      
    }
  end
  
  
  def summary
    "#{delegator_screen_name} to #{delegated_screen_name}"
  end
  
  def self.lookup
    :summary
  end
  
  def delegator_screen_name
    delegator_attrs['screen_name']
  end
  
  def delegated_screen_name
    delegated_attrs['screen_name']
  end  
  
  def self.tree(poll, user_id)    
    delegations = Delegation.where(delegated: /^#{user_id}$/i, poll: poll)
    if delegations.count > 0
      x = []
      delegations.each { |delegation|        
          x << delegation.delegator                  
          if subtree = Delegation.tree(poll, delegation.delegator)
            x << subtree
          end           
      }
      x
    end        
  end
  
  def trace
    x = []    
    delegation = self
    while delegation and !x.include?(delegation.delegated)
      x << delegation.delegated 
      delegation = Delegation.find_by(delegator: /^#{delegation.delegated}$/i, poll: poll)
    end  
    x
  end
     
end
