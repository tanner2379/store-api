class CreateOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :orders do |t|
      t.references :invoice, null: false, foreign_key: true
      t.integer :product_id
      t.string :product_name
      t.float :product_price
      t.integer :quantity

      t.timestamps
    end
  end
end
