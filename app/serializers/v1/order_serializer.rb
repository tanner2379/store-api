class V1::OrderSerializer < ActiveModel::Serializer
  attributes :id, :product_id, :quantity, :product_name


  def product_name
    Product.find(object.product_id).name
  end
end
