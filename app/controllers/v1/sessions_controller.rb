class V1::SessionsController < V1::ApiController

  def create
    user = User
      .find_by(email: params['user']['email'])
      .try(:authenticate, params['user']['password'])
    
    if user
      session[:user_id] = user.id

      cart_items = CartItem.where(session_id: cookies.encrypted[:cart_tracker]);

      if cart_items.first
        cart_items.each do |cart_item|
          cart_item.update!(user_id: user.id);
        end
      end
      
      render json: {
        status: :created,
        logged_in: true,
        user: user
      }
    else
      render json: {
        status: 401,
        errors: ['Username or Password Incorrect']
      }
    end
  end

  def logged_in
    if @current_user
      render json: {
        logged_in: true,
        user: @current_user
      }
    else
      render json: {
        logged_in: false,
      }
    end
  end

  def logout
    reset_session
    render json: {
      status: 200,
      logged_out: true
    }
  end
end