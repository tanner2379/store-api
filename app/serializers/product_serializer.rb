class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :slug, :order_count
  has_many :images, serializer: ImageSerializer

  def order_count
    Order.where(product_id: object.id).count
  end
end
