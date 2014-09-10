class SessionController < ApplicationController

  
  def new
    
  end
  
  def create
    ldap_connection = connect_to_ldap_server  
    if ldap_connection
      flash[:notice] = "Success connection"  
      login_info = authenticate_through_ldap(ldap_connection, params[:emp_id], params[:password])
      if !login_info.blank?
        user = User.update_or_create_user_info(login_info) 
        if user 
          authenticate_through_session(user)                
          flash[:notice] = "Successful signin" 
          redirect_to profile_user_path(user.id)
        end

      else
      flash[:notice] = "The user name or password you entered isn't correct. Try entering it again."  
      render new_session_path and return        
      end
    else  
      flash[:notice] = "Unable to connect LDAP server."  
    end
  end
  

 def logout
 session[:user] = nil
 redirect_to root_url  
 end
 
  def connect_to_ldap_server
    ldap = Net::LDAP.new :host => '10.237.5.106',
    :port => 3268,
    :auth => {
      :method => :simple,
      :username => "systompun",
      :password => "password-1"
     }
  end
  
def authenticate_through_ldap(ldap_connection,emp_id, password)
  filter = Net::LDAP::Filter.eq("sAMAccountName", emp_id)
  treebase = "dc=cts,dc=com"
  user_details = Hash.new
  authenticate_ldap_user = ldap_connection.bind_as(:base => treebase, :filter => filter, :password => password)

  if authenticate_ldap_user
    user_details = ldap_user_search(ldap_connection, emp_id)
    return  user_details
  else
    return ""
  end  
end

def ldap_user_search(ldap, user_id)
  user_details = Hash.new
  filter = Net::LDAP::Filter.eq("sAMAccountName", user_id)
  treebase = "dc=cts,dc=com"  
  ldap.search(:base => treebase, :filter => filter, :attributes => User::USER_ATTRIBUTES) do |entry|
 
  entry.each do |attribute, values|
    values.each do |value|
      user_details[attribute.to_sym] = value
    end
  end
  end  
  user_details
end
  
end
