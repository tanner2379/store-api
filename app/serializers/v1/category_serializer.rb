class V1::CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :image_url, :slug

  def image_url
    Rails.application.routes.url_helpers.rails_blob_url(object.image, only_path: true)
  end

end