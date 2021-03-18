class V1::ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :slug, :order_count
  has_many :images, serializer: V1::ImageSerializer

  def order_count
    Order.where(product_id: object.id).count
  end
end
