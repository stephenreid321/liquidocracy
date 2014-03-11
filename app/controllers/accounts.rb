ActivateApp::App.controller :accounts do
            
  get :show, :map => '/:screen_name' do    
    @account = Account.find_by(screen_name: params[:screen_name]) || not_found
    @open_polls = @account.polls.still_open.order_by(:closes.asc)
    @closed_polls = @account.polls.closed.order_by(:closes.desc)         
    erb :'accounts/show'
  end
  
  get :check do
    sign_in_required!
    current_account.check
    redirect back
  end
            
  get :edit do
    sign_in_required!
    @account = current_account
    erb :'accounts/build'
  end
  
  post :edit do
    sign_in_required!
    @account = current_account
    if @account.update_attributes(params[:account])      
      flash[:notice] = "<strong>Awesome!</strong> Your account was updated successfully."
      redirect url(:accounts_edit)
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
  
  get :sign_out do
    session.clear
    redirect url(:home)
  end
   
end