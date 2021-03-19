class V1::OrderSerializer < ActiveModel::Serializer
  attributes :id, :product_id, :product_name, :product_price, :quantity

end
