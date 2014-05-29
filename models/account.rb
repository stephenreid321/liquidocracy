class Account
  include Mongoid::Document
  include Mongoid::Timestamps
            
  field :role, :type => String, :default => 'user'
  field :time_zone, :type => String
  field :user_id, :type => String
  field :screen_name, :type => String
  field :user_attrs, :type => Hash
  field :omniauth_hash, :type => Hash  
  field :last_checked, :type => Time
  field :most_recent_tweet_id, :type => Integer
  field :most_recent_but_one_tweet_id, :type => Integer
  
  has_many :polls, :dependent => :destroy
  has_many :nominations, :dependent => :destroy
                          
  validates_presence_of :role, :time_zone, :user_id, :screen_name, :user_attrs, :omniauth_hash  
  validates_uniqueness_of :user_id
  validates_uniqueness_of :screen_name

  def self.fields_for_index
    [:user_id, :screen_name, :role, :time_zone, :last_checked, :most_recent_tweet_id, :most_recent_but_one_tweet_id]
  end
  
  def self.fields_for_form
    {
      :user_id => :disabled_text,
      :screen_name => :disabled_text,
      :role => :select,
      :time_zone => :select,
      :last_checked => :disabled_text_area,
      :most_recent_tweet_id => :disabled_text_area,
      :most_recent_but_one_tweet_id => :disabled_text_area,
      :polls => :collection,
      :nominations => :collection,
      :user_attrs => :disabled_text_area
    }
  end
           
  def self.time_zones
    ['']+ActiveSupport::TimeZone::MAPPING.keys.sort
  end  
  
  def self.roles
    ['user','admin']
  end    
  
  def self.lookup
    :screen_name
  end
  
  def name
    user_attrs['name']
  end
    
  def api
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_KEY']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = omniauth_hash['credentials']['token']
      config.access_token_secret = omniauth_hash['credentials']['secret']
    end  
  end

  def check
    # TODO: get all tweets since last considered - guess would have to be done using a worker process and sleep()?
    #    if most_recent_tweet_id and most_recent_but_one_tweet_id
    #      x = api.mentions(count: 200, since_id: most_recent_but_one_tweet_id)
    #      until x.map(&:id).include?(most_recent_tweet_id)
    #        x = x + api.mentions(count: 200, max_id: x.last.id, since_id: most_recent_but_one_tweet_id)
    #      end
    #    else
    begin
      x = api.mentions(count: 200)
    rescue
      return nil
    end
    #    end
    x.reverse!
    x.each { |tweet|
      puts tweet.text
      if tweet.in_reply_to_status_id
        if poll = polls.find_by(status_id: tweet.in_reply_to_status_id)
          if !poll.restricted or (poll.restricted and api.friendship?(user_id.to_i,tweet.user.id))
            if (match = tweet.text.match(/vote for (.+)/))
              puts match
              option = poll.options.find_by(slug: match.to_a[1])
              if option
                poll.delegations.find_by(:delegator => /^#{tweet.user.id}$/i).try(:destroy)
                poll.votes.find_by(:user_id => /^#{tweet.user.id}$/i).try(:destroy)
                option.votes.create :user_id => tweet.user.id, :tweet_attrs => tweet.attrs
              end
            elsif (match = tweet.text.match(/remove vote/))
              puts match
              poll.votes.find_by(:user_id => /^#{tweet.user.id}$/i).try(:destroy)
            elsif (match = tweet.text.match(/delegate to @(.+)/))       
              puts match
              begin
                delegated_user = api.user(match.to_a[1])
                poll.delegations.find_by(:delegator => /^#{tweet.user.id}$/i).try(:destroy)
                poll.votes.find_by(:user_id => /^#{tweet.user.id}$/i).try(:destroy)
                poll.delegations.create :delegator => tweet.user.id, :delegated => delegated_user[:id], :tweet_attrs => tweet.attrs, :delegator_attrs => tweet.attrs[:user], :delegated_attrs => delegated_user.attrs
              rescue Twitter::Error::NotFound
                nil
              end
            elsif (match = tweet.text.match(/stop delegating/))
              puts match
              poll.delegations.find_by(:delegator => /^#{tweet.user.id}$/i).try(:destroy)
            end
          end
        end
      else
        if (match = tweet.text.match(/delegate #(.+) to @(.+)/))   
          puts match
          begin            
            nominated_user = api.user(match.to_a[2])
            tag = Tag.find_or_create_by(name: match.to_a[1])            
            nominations.find_by(:nominator => /^#{tweet.user.id}$/i, :tag => tag).try(:destroy)
            nominations.create :nominator => tweet.user.id, :tag => tag, :nominated => nominated_user[:id], :tweet_attrs => tweet.attrs, :nominator_attrs => tweet.attrs[:user], :nominated_attrs => nominated_user.attrs
          rescue Twitter::Error::NotFound
            nil
          end          
        elsif (match = tweet.text.match(/stop delegating #(.+)/))
          puts match
          tag = Tag.find_or_create_by(name: match.to_a[1])
          nominations.find_by(:nominator => /^#{tweet.user.id}$/i, :tag => tag).try(:destroy)
        elsif (match = tweet.text.match(/delegate all to @(.+)/))
          puts match
          begin
            nominated_user = api.user(match.to_a[1])
            nominations.find_by(:nominator => /^#{tweet.user.id}$/i).try(:destroy)            
            nominations.create :nominator => tweet.user.id, :nominated => nominated_user[:id], :tweet_attrs => tweet.attrs, :nominator_attrs => tweet.attrs[:user], :nominated_attrs => nominated_user.attrs
          rescue Twitter::Error::NotFound
            nil
          end           
        elsif (match = tweet.text.match(/stop delegating/))
          puts match
          nominations.find_by(:nominator => /^#{tweet.user.id}$/i).try(:destroy)          
        end
      end
    }
    if x.length >= 2
      self.update_attribute(:most_recent_tweet_id, x[-1].id)
      self.update_attribute(:most_recent_but_one_tweet_id, x[-2].id)
    end
    self.update_attribute(:last_checked, Time.now)
    x
  end
  
  def self.authenticate(screen_name, password)
    account = find_by(screen_name: /^#{Regexp.escape(screen_name)}$/i) if screen_name.present?
    account && (password == ENV['ADMIN_PASSWORD']) ? account : nil
  end
    
end
