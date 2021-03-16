class User < ApplicationRecord
  has_many :payment_methods
  has_secure_password

  validates_presence_of :email
  validates_uniqueness_of :email

  def cart_items
    CartItem.where(user_id: self.id)
  end

  def shipping_addresses
    ShippingAddress.where(user_id: self.id)
  end

  def payment_options
    payment_options = []
    self.payment_methods.each do |payment_method|
      if payment_method.expired?
        payment_options.append(["EXPIRED Card ending in #{payment_method.last4}", payment_method.id])
      else
        payment_options.append(["Card ending in #{payment_method.last4}", payment_method.id])
      end
    end
    payment_options
  end

  def shipping_options
    shipping_options = []
    self.shipping_addresses.each do |shipping_address|
      shipping_options.append([shipping_address.address_line1, shipping_address.id])
    end
    shipping_options
  end
end
