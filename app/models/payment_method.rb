class PaymentMethod < ApplicationRecord
  belongs_to :user
  validates :stripe_id, presence: true, uniqueness: true

  def retrieve
    Stripe::PaymentMethod.retrieve(self.stripe_id,)
  end

  def last4
    self.retrieve.card.last4
  end

  def exp_month
    self.retrieve.card.exp_month
  end

  def exp_year
    self.retrieve.card.exp_year
  end

  def expired?
    date = DateTime.now
    if date.year > self.exp_year
      return true
    elsif (date.year == self.exp_year && date.month > self.exp_month)
      return true
    else
      return false
    end
  end
end