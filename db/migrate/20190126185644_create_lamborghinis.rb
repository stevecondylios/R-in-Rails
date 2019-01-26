class CreateLamborghinis < ActiveRecord::Migration[5.2]
  def change
    create_table :lamborghinis do |t|
      t.string :name
      t.decimal :price
      t.integer :year

      t.timestamps
    end
  end
end
