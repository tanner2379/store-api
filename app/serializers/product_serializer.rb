class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :price, :slug
  has_many :images, serializer: ImageSerializer

end
