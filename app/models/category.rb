class Category < ApplicationRecord
  before_create :set_slug
  before_update :set_slug

  validates_presence_of :name
  has_many :product_categories
  has_many :products, through: :product_categories
  default_scope { order(name: :asc) }

  private
  
  def set_slug
    self.slug = self.name.parameterize
  end
end
