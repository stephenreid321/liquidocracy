ActivateApp::App.helpers do
  
  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end
  
  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect('/auth/twitter/')
    end
  end  
  
  def twitter_thumb(attrs, internal: false, size: nil)
    attrs = attrs.with_indifferent_access
    url = internal ? url(:accounts_show, :screen_name => attrs[:screen_name]) : "http://twitter.com/intent/user?user_id=#{attrs[:id]}"
    width = (case size; when 'original'; '240px'; when 'bigger'; '73px'; else; '48px'; end)    
    src = attrs[:profile_image_url]
    begin
      Mechanize.new.get(src)
      case size; when 'original'; src.gsub!('_normal', ''); when 'bigger'; src.gsub!('_normal', '_bigger'); end       
    rescue
      src = '/images/silhouette.png'
    end    
    %Q{<a href="#{url}"><img style="width: #{width}" src="#{src}" alt="#{attrs[:screen_name]}" title="#{attrs[:screen_name]}"></a>}    
  end    
  
  def newick(nested_array)
    n = '<ul>'
    nested_array.each_with_index { |x,i|      
      if x.is_a? String
        n << '<li>'
        n << x
        if nested_array[i+1].is_a? Array
          n << newick(nested_array[i+1])
        end
        n << '</li>'
      end    
    }   
    n << '</ul>'
    n.html_safe
  end
        
  # Amount should be a decimal between 0 and 1. Lower means darker
  def darken_color(rgb_color, amount=0.4)    
    rgb_color = rgb_color.gsub('rgb(','')
    rgb_color = rgb_color.gsub(')','')
    rgb = rgb_color.split(',').map(&:strip)
    rgb[0] = (rgb[0].to_i * amount).round
    rgb[1] = (rgb[1].to_i * amount).round
    rgb[2] = (rgb[2].to_i * amount).round
    "#%02x%02x%02x" % rgb
  end
  
  # Amount should be a decimal between 0 and 1. Higher means lighter
  def lighten_color(rgb_color, amount=0.6)
    rgb_color = rgb_color.gsub('rgb(','')
    rgb_color = rgb_color.gsub(')','')
    rgb = rgb_color.split(',').map(&:strip)
    rgb[0] = [(rgb[0].to_i + 255 * amount).round, 255].min
    rgb[1] = [(rgb[1].to_i + 255 * amount).round, 255].min
    rgb[2] = [(rgb[2].to_i + 255 * amount).round, 255].min
    "#%02x%02x%02x" % rgb
  end  
    
  
end