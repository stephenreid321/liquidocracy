class Poll
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
  
  field :question, :type => String
  field :closes, :type => ActiveSupport::TimeWithZone
  field :details, :type => String  
  field :tweet_attrs, :type => Hash
  field :status_id, :type => String
  field :slug, :type => Integer
  field :restricted, :type => Boolean, :default => false
    
  has_many :options, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :delegations, :dependent => :destroy  
  has_many :tagships, :dependent => :destroy
  
  validates_presence_of :question, :closes, :details, :slug, :account # :tweet_attrs, :status_id
  
  accepts_nested_attributes_for :options, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :tagships, allow_destroy: true, reject_if: :all_blank
    
  def self.fields_for_index
    [:account_id, :slug, :restricted, :status_id, :question, :closes]
  end
  
  def self.fields_for_form
    { 
      :account_id => :lookup,
      :question => :text,
      :closes => :datetime,
      :details => :text_area,
      :restricted => :check_box,
      :tweet_attrs => :disabled_text_area,
      :status_id => :disabled_text,
      :tagships => :collection,
      :options => :collection,
      :votes => :collection,
      :delegations => :collection
    }
  end
   
  before_validation :restricted_to_boolean
  def restricted_to_boolean
    self.restricted = true if ['1', true].include?(self.restricted)
    self.restricted = false if ['0', false].include?(self.restricted)
    return true
  end  
    
  before_validation :check_closes_is_in_the_future
  def check_closes_is_in_the_future
    errors.add(:closes, "must be at least 15 minutes from now") unless self.closes > Time.now + 15.minutes
  end   
      
  before_validation :check_for_options
  def check_for_options
    errors.add(:options, "Please enter some options") if options.empty?
  end  
  
  before_validation :set_slug
  def set_slug
    if !self.slug
      if Poll.count > 0
        self.slug = Poll.only(:slug).order_by(:slug.desc).first.slug + 1
      else
        self.slug = 1
      end
    end
  end
  
  scope :closed, where(:closes.lte => Time.now)
  scope :still_open, where(:closes.gt => Time.now)  
  
  def question_with_tags
    "#{question} <small>#{tagships.map { |tagship| "##{tagship.name}"}.join(' ')}</small>"
  end
  
  def self.colors
    %w{
      rgb(179,134,219)
      rgb(134,158,219)
      rgb(134,190,219)
      rgb(134,219,209)
      rgb(134,219,139)
      rgb(201,219,134)  
      rgb(219,195,134)
      rgb(219,134,186)
      rgb(219,134,135)
    }
  end
  
  def color
    Poll.colors[0]
  end
  
  def closed?
    Time.now > self.closes
  end
  
  def open?
    !closed?
  end  
  
  def self.lookup
    :question
  end   
  
  after_create :broadcast
  def broadcast   
    content = " Vote at http://#{ENV['DOMAIN']}/polls/#{slug}"
    if !self.tagships.empty?
      content = ' ' + self.tagships.map { |tagship| "##{tagship.name}" }.join(' ') + content
    end
    space = 140-content.length
    if self.question.length <= space        
      content = self.question + content
    else
      content = self.question[0..(space-4)] + '...' + content
    end    
    self.tweet_attrs = account.api.update(content).attrs
    self.status_id = self.tweet_attrs[:id]
    self.save!
  end

  after_create :turn_nominations_into_delegations  
  def turn_nominations_into_delegations
    account.nominations.each { |nomination|
      if !nomination.tag or (nomination.tag and self.tagships.find_by(tag: nomination.tag))
        delegations.create!(delegator: nomination.nominator, delegated: nomination.nominated, delegator_attrs: nomination.nominator_attrs, delegated_attrs: nomination.nominated_attrs)
      end
    }
  end  
    
  def weight
    options.sum(&:weight)
  end
  
  def result
    self.options.sort_by(&:weight).reverse.first if self.votes.count > 0
  end  
  
  def self.human_attribute_name(attr, options={})  
    {
      :status_id => "Status ID",
      :restricted => "Only allow people I follow to take part"
    }[attr.to_sym] || super  
  end    
    
end