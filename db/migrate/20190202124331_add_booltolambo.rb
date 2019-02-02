class AddBooltolambo < ActiveRecord::Migration[5.2]
  def change
    add_column :lamborghinis, :yes_no, :boolean
  end
end
