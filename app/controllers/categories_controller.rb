class CategoriesController < ApplicationController
  before_action :require_user, only: [:create, :update, :destroy]
  before_action :require_vendor, only: [:create, :update, :destroy]

  before_action :set_category, only: [:show, :edit, :update, :destroy]

  def index
    @categories = Category.all
    render json: @categories
  end

  def show

    products = [];
    @category.products.each do |product|
      products.append(ProductSerializer.new(product))
    end
    render json: {
      category: @category.name,
      products: products
    }
  end

  def create
    category = Category.create!(category_params);

    if category
      render json: {
        status: :created,
        category: category
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def update
    if @category.update(category_params)
      render json: {
        status: :updated,
        category: @category
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def destroy
    if @category.destroy
      render json: {
        status: :deleted
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def just_category
    @category = Category.find_by(slug: params[:category_slug])
    render json: {
      category: @category.name
    }
  end


  private

  def set_category
    @category = Category.find_by(slug: params[:slug])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end