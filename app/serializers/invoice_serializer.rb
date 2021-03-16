class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :shipped_date, :shipping_company, :tracking_number, :total_price
  has_many :orders, serializer: OrderSerializer
  has_one :shipping_address, serializer: ShippingAddressSerializer

  def total_price
    total_price = 0
    object.orders.each do |order|
      total_price += order.total_price
    end
    total_price
  end
end
