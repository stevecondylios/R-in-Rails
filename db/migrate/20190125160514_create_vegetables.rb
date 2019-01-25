class CreateVegetables < ActiveRecord::Migration[5.2]
  def change
    create_table :vegetables do |t|
      t.string :name
      t.decimal :weight

      t.timestamps
    end
  end
end
