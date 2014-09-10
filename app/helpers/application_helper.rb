module ApplicationHelper
  
  def is_user_profile?(user)
    return false unless session[:user]
    return session[:user].id == user.id ? true : false
  end
  
  def logged_in?
    return session[:user].blank? ? false : true
  end
  
  def role_based_skill_path(skill)
    if is_admin?
     skill_path(skill.id)
    else
     similar_skill_user_path(:skill => skill.id)
    end

  end
  
  def role_based_profile_path
    '#'
  end
  
  def is_admin?
    (!session[:user].blank? and session[:user][:title] == "Manager - Projects") ? true : false
  end
end
