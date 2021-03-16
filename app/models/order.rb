class Order < ApplicationRecord
  belongs_to :invoice
  belongs_to :product
  validates_presence_of :quantity

  def total_price
    self.product.price * self.quantity
  end
end
