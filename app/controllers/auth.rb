ActivateApp::App.controller do
    
  get '/auth/failure' do
    flash.now[:error] = "<strong>Hmm.</strong> There was a problem signing you in."
    erb :home
  end
  
  %w(get post).each do |method|
    send(method, "/auth/twitter/callback") do    
      if current_account # already signed in and hence connected
        flash[:notice] = "Chill out, you're already signed up and signed in"
        redirect url(:home)
      else
        if (account = Account.find_by(user_id: env['omniauth.auth']['uid'])) # already connected; sign in
          env['omniauth.auth'].delete('extra')
          account.omniauth_hash = env['omniauth.auth']
          account.user_attrs = account.api.user(env['omniauth.auth']['uid'].to_i).attrs
          account.screen_name = env['omniauth.auth']['info']['nickname']
          account.save!
          session['account_id'] = account.id
          flash[:notice] = "Signed in!"
          if session[:return_to]
            redirect session[:return_to]
          else
            redirect url(:accounts_show, :screen_name => account.screen_name)
          end
        else # sign up          
          @account = Account.new
          env['omniauth.auth'].delete('extra')
          @account.user_id = env['omniauth.auth']['uid']
          @account.omniauth_hash = env['omniauth.auth']
          @account.user_attrs = @account.api.user(env['omniauth.auth']['uid'].to_i).attrs
          @account.screen_name = env['omniauth.auth']['info']['nickname']
          @account.time_zone = 'London'          
          @account.save!
          session['account_id'] = @account.id
          flash[:notice] = "<strong>Awesome!</strong> Your account was created successfully."          
          redirect url(:accounts_show, :screen_name => @account.screen_name)
        end
      end
    end
  end 
  
end