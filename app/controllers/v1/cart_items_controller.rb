class V1::CartItemsController < V1::ApiController
  before_action :set_cart_item, only: [:update, :destroy]

  def index
    if user_signed_in?
      @cart_items = CartItem.where(user_id: @current_user.id)
    else
      if cookies.encrypted[:cart_tracker] == nil
        @cart_items = []
      else
        @cart_items = CartItem.where(session_id: cookies.encrypted[:cart_tracker])
      end
    end

    if @cart_items.first
      cart_items_transformed = []
      @cart_items.each do |cart_item|
        product = cart_item.product
        image = V1::ImageSerializer.new(product.images.first)
        cart_item_transformed = {id: cart_item.id, product_name: product.name, product_price: product.price, product_in_stock: product.in_stock, quantity: cart_item.quantity, image_url: image.url}
        cart_items_transformed.append(cart_item_transformed)
      end

      render json: {
        status: 200,
        cart_items: cart_items_transformed
      }
    else
      render json: {
        status: :no_items
      }
    end
  end

  def create
    if params[:quantity] != ""
      product = Product.find(params[:product_id])
      warning = nil
      if product.in_stock >= params[:quantity]
        quantity = params[:quantity]
      else
        quantity = product.in_stock
        warning = "Unable to fulfill quantity"
      end
    else
      if product.in_stock >= 1
        quantity = 1
      else
        render json: {
          warning: "Out of Stock"
        }
      end
    end

    if CartItem.exists?(product_id: params[:product_id])
      if user_signed_in?
        @cart_item = CartItem.where(product_id: params[:product_id], user_id: current_user.id).first
        if !@cart_item
          @cart_item = CartItem.where(product_id: params[:product_id], session_id: cookies.encrypted[:cart_tracker]).first
          @cart_item.update!(user_id: current_user.id, session_id: nil)
        end
      else
        @cart_item = CartItem.where(product_id: params[:product_id], session_id: cookies.encrypted[:cart_tracker]).first
      end
      @cart_item.quantity = @cart_item.quantity + quantity.to_i
    else
      if !params[:user_id] && !params[:session_id]
        ip = request.remote_ip.gsub(".", "")
        cookies.encrypted[:cart_tracker] = {value: ip}
        @cart_item = CartItem.new(session_id: cookies.encrypted[:cart_tracker], product_id: params[:product_id], quantity: quantity)
      else
        @cart_item = CartItem.create(cart_item_params.except(:quantity))
        @cart_item.quantity = quantity
      end
    end
    
    if @cart_item.save
      render json: {
        status: :created,
        cart_item: @cart_item,
        warning: warning
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def update
    if @cart_item.update!(quantity: params[:quantity])
      if @cart_item.quantity == 0
        @cart_item.destroy
      end
      render json: {
        status: 200
      }
    else
      render json: {
        status: 500
      }
    end

  end

  def destroy
    if @cart_item.destroy
      render json: {
        status: :deleted
      }
    else
      render json: {
        status: 500
      }
    end
  end

  private

  def set_cart_item
    @cart_item = CartItem.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def cart_item_params
    params.permit(:user_id, :session_id, :product_id, :quantity)
  end
end