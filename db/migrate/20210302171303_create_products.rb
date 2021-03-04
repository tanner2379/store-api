class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.float :price
      t.string :slug, unique: true

      t.timestamps
    end
  end
end
