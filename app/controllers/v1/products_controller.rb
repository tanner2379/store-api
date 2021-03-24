class V1::ProductsController < V1::ApiController
  before_action :require_user, only: [:create, :update, :destroy]
  before_action :require_vendor, only: [:create, :update, :destroy]
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    @products = Product.all
    render json: @products
  end

  # GET /products/1
  # GET /products/1.json
  def show
    render json: @product
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.create(product_params)

    if @product.save
      render json: {
        status: :created,
        product: @product
      }
    else
      render json: {
        status: 500
      }
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    if @product.update(product_params)
      render json: {
        status: :updated,
        product: @product
      }
    else
      render json: {
        status: 500
      }
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    CartItem.where(product_id: @product.id).delete_all
    if @product.destroy
      render json: {
        status: :deleted
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def search
    query = params[:product_name]
    if query == ""
      @products = nil
    else
      @products = Product.where("#{:name} LIKE ?", "%#{query}%")
    end
    if @products || @products == nil
      render json: @products
    else
      render json: @products
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find_by(slug: params[:slug])
  end

  # Only allow a list of trusted parameters through.
  def product_params
    params.permit(:name, :description, :price, :in_stock, images: [])
  end
end