class SkillSet < ActiveRecord::Base
  attr_accessible :user_id, :skill_id, :level
  belongs_to :user
  belongs_to :skill
  
  default_scope order('level DESC')
  
  
end
