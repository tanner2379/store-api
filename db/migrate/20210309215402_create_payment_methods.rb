class CreatePaymentMethods < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_methods do |t|
      t.string :stripe_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
