class User < ActiveRecord::Base
  attr_accessible :emp_id, :name, :email, :title
  has_many :skill_sets
  has_many :skills, :through => :skill_sets
  
  USER_ATTRIBUTES = ["l", "title", "description", "physicaldeliveryofficename", "givenname", "whencreated", 
                     "displayname", "department", "company", "streetaddress", "name", "samaccountname",
                     "mail", "manager", "mobile"]
  
  
  def self.update_or_create_user_info(user_info)
    user = find_by_email(user_info[:mail])
    if !user.blank?
      #todo update user with latest login info
      return user
    else
      user = User.create(:email => user_info[:mail], :name => user_info[:givenname], :emp_id =>  user_info[:samaccountname], :title => user_info[:title])      
      if user
        return user 
      else
        return ""  
      end
    end    
  end

  def skills_list(size=0)
    list = []
    skills.each{|s| list << s.name}
    list= list.size < size ? list :  list[0..size]
    return list.join(",") unless list.empty?
    "No skills added"
  end
  
  def skill_level(skill)
    skill_level = skill_sets.find_by_skill_id(skill.id)
    skill_level.blank? ? 1 :  skill_level
  end
  
  def skillset_last_updated_on
    return "" if skill_sets.empty?
    return skill_sets.first.created_at.strftime("%m/%d/%y")
  end
  
  def similar_skill_users(skill=nil)
    if skill
      skill_ids = skills.where("skills.id = #{skill.id}").map(&:id)
    else
      skill_ids = skills.map(&:id)
    end
    if skill_ids.size == 1
      User.joins(:skill_sets).where("skill_sets.skill_id = #{skill_ids[0]} and users.id != #{self.id}").group("users.id").includes(:skill_sets) 
    else
      User.joins(:skill_sets).where("skill_sets.skill_id in (#{skill_ids.join(',')}) and users.id != #{self.id}").group("users.id").includes(:skill_sets)   
    end
    
  end
  
end
