class Invoice < ApplicationRecord
  belongs_to :shipping_address
  has_many :orders, dependent: :delete_all
end
