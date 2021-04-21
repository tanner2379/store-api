class Category < ApplicationRecord
  before_create :set_slug
  before_update :set_slug

  validates_presence_of :name
  validate :acceptable_image

  has_one_attached :image, dependent: :delete
  has_many :product_categories
  has_many :products, through: :product_categories
  default_scope { order(name: :asc) }

  private

  def acceptable_image  
    acceptable_types = ["image/jpeg", "image/png"]
    unless acceptable_types.include?(image.content_type)
      errors.add(:main_image, "must be a JPEG or PNG")
    end
  end
  
  def set_slug
    self.slug = self.name.parameterize
  end
end
