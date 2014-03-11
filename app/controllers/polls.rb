ActivateApp::App.controllers :polls do
       
  get :new do
    sign_in_required!
    @poll = current_account.polls.build
    erb :'polls/build'
  end  
  
  post :new do
    sign_in_required!
    @poll = current_account.polls.build(params[:poll])
    if @poll.save
      flash[:notice] = "<strong>Awesome!</strong> The poll was created successfully."
      redirect(url(:polls_show, slug: @poll.slug))
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the poll from being saved."
      erb :'polls/build'
    end
  end
  
  get :show, :map => '/polls/:slug' do
    @poll = Poll.find_by(slug: params[:slug]) || not_found
    erb :'polls/show'
  end   
   
  get :edit, :with => :id do
    sign_in_required!
    raise "Editing of polls is not allowed"
    @poll = current_account.polls.find(params[:id])
    erb :'polls/build'
  end

  post :edit, :with => :id do  
    sign_in_required!    
    raise "Editing of polls is not allowed"
    @poll = current_account.polls.find(params[:id]) 
    if @poll.update_attributes(params[:poll])
      flash[:notice] = "<strong>Sweet!</strong> The poll was updated successfully."      
      redirect(url(:polls_show, slug: @poll.slug))
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the poll from being saved."
      erb :'polls/build'
    end
  end

  get :destroy, :with => :id do
    sign_in_required!    
    @poll = current_account.polls.find(params[:id]) 
    if @poll.destroy
      flash[:notice] = "<strong>Boom!</strong> The poll was deleted."
    else
      flash[:error] = "<strong>Darn!</strong> The poll couldn't be deleted."
    end
    redirect url(:accounts_show, :screen_name => current_account.screen_name)
  end 
  
end