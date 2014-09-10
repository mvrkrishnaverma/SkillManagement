class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def authenticate_through_session(user)
    if session[:user].blank?
      session[:user] = user
    end
  end
  
  def authenticate_user
    redirect_to new_session_path unless session[:user]
    return true
  end
end
