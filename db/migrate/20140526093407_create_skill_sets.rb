class CreateSkillSets < ActiveRecord::Migration
  def change
    create_table :skill_sets do |t|
      t.belongs_to :user
      t.belongs_to :skill
      t.integer :level
      t.timestamps
    end
  end
end
