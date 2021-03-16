class CreateShippingAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :shipping_addresses do |t|
      t.integer :user_id
      t.string :name, required: true
      t.string :address_line1, required: true
      t.string :city, required: true
      t.string :country, required: true
      t.string :address_line2
      t.string :postal_code, required: true
      t.string :state

      t.timestamps
    end
  end
end
