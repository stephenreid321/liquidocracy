module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers
    
    set :sessions, :expire_after => 1.year
    # set :show_exceptions, true
    set :public_folder,  Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'
      
    before do
      redirect "http://#{ENV['DOMAIN']}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!
    end     
    
    #  register Padrino::Mailer
    #  set :delivery_method, :smtp => { 
    #    :address              => "smtp.gmail.com",
    #    :port                 => 587,
    #    :user_name            => ENV['GMAIL_USERNAME'],
    #    :password             => ENV['GMAIL_PASSWORD'],
    #    :authentication       => :plain,
    #    :enable_starttls_auto => true  
    #  }    
    
    if defined? Dragonfly
      use Dragonfly::Middleware
    end    
  
    if defined? OmniAuth
      use OmniAuth::Builder do
        provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
      end  
      OmniAuth.config.on_failure = Proc.new { |env|
        OmniAuth::FailureEndpoint.new(env).redirect_to_failure
      }
    end
  
    if defined? Rack::Cache
      use Rack::Cache, :metastore => Dalli::Client.new, :entitystore  => 'file:tmp/cache/rack/body', :allow_reload => false
    end
          
    if defined? Airbrake
      use Airbrake::Rack  
      error do
        Airbrake.notify(env['sinatra.error'], :session => session) if Padrino.env == :production
        erb :error, :layout => :application
      end      
      get '/airbrake' do
        raise StandardError
      end
    end    
    
    not_found do
      erb :not_found, :layout => :application
    end
    
    get :home, :map => '/' do
      erb :home
    end
    
    get :about, :map => '/about' do
      erb :about
    end    
     
  end         
end
