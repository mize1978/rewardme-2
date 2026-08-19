class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :due_on
      t.datetime :completed_at

      t.timestamps
    end
  end
end
