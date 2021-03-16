class CreateInvoices < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices do |t|
      t.references :shipping_address, null: false, foreign_key: true
      t.datetime :shipped_date
      t.string :shipping_company
      t.string :tracking_number
      
      t.timestamps
    end
  end
end
