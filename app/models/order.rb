class Order < ApplicationRecord
  belongs_to :invoice
  validates_presence_of :product_id, :product_name, :product_price, :quantity

  def total_price
    product = Product.find(self.product_id)
    product.price * self.quantity
  end
end
