class Product < ApplicationRecord
  before_create :set_slug
  before_update :set_slug
  
  has_many :orders
  validates :name, presence: true, uniqueness: true
  validates_presence_of :description
  validates_presence_of :price
  validate :acceptable_image

  has_many_attached :images
  has_many :product_categories
  has_many :categories, through: :product_categories

  private

  def acceptable_image  
    acceptable_types = ["image/jpeg", "image/png"]
    images.each do |image|
      unless acceptable_types.include?(image.content_type)
        errors.add(:main_image, "must be a JPEG or PNG")
        break
      end
    end
  end

  def first_image_url
    Rails.application.routes.url_helpers.rails_blob_url(self.images.first, only_path: true)
  end

  def set_slug
    self.slug = self.name.parameterize
  end
end
