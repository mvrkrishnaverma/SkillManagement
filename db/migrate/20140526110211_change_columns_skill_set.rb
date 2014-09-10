class ChangeColumnsSkillSet < ActiveRecord::Migration
  def up
    change_column :skill_sets, :skill_id, :integer
    change_column :skill_sets, :user_id, :integer
  end

  def down
  end
end
