module UsersHelper
  
  def user_has_skill(user, skill)
    skill_ids = user.skills.map(&:id)
    return false,1 if skill_ids.empty?
    return false,1 if !skill_ids.include?(skill.id.to_i)  
    return true, user.skill_level(skill)
  end
end
