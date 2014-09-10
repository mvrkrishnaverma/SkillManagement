class Skill < ActiveRecord::Base
  attr_accessible :description, :name, :category_id
  has_many :skill_sets, :class_name => "SkillSet"
  has_many :users, :through => :skill_sets
  belongs_to :category
end
