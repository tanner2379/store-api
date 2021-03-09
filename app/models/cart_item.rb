class CartItem < ApplicationRecord
  validates_presence_of :product_id
  validates_presence_of :quantity
  validate :must_have_either_user_id_or_session_id
  
  def user
    if self.user_id
      User.find(self.user_id)
    end
  end

  def product
    Product.find(self.product_id)
  end

  def total_price
    Product.find(self.product_id).price * self.quantity
  end

  private

  def must_have_either_user_id_or_session_id
    if !user_id && !session_id
      errors.add(:id, "must have user_id or session_id")
    elsif user_id && session_id
      errors.add(:id, "can't have both user_id and session_id")
    end
  end
end