class ShippingAddress < ApplicationRecord
  has_many :invoices
  validates_presence_of :name, :address_line1, :city, :country, :postal_code
  validate :usa_must_have_state

  def user
    User.find(self.user_id)
  end

  private

  def usa_must_have_state
    if self.country == "US"
      if !self.state
        errors.add("Must have state if within the US")
      end
    end
  end
end