class ApplicationController < ActionController::Base
  include CurrentUserConcern
  skip_before_action :verify_authenticity_token

  def current_user
    @current_user
  end
  
  def user_signed_in?
    if current_user
      return true
    else
      return false
    end
  end

  def require_user
    if !user_signed_in?
      render json: {
        status: 401
      }
    end
  end

  def require_vendor
    if !current_user.vendor
      render json: {
        status: 401
      }
    end
  end
end

def validate_payment(payment)
  return false if payment[:card_number].to_i.to_s.length != 16
  return false if payment[:card_cvv].to_i.to_s.length != 3

  return false if payment[:card_expires_month] == ""
  return false if payment[:card_expires_year] == ""

  return true
end

def validate_payment_method(payment_method)
  if user_signed_in?
    payment_method = Stripe::PaymentMethod.retrieve(payment_method,)
    if payment_method.customer == current_user.stripe_customer_id
      return true
    else
      return false
    end
  else
    return false
  end
end

def create_payment(total_price, payment_method, shipping_details)
  if user_signed_in?
    payment_intent = Stripe::PaymentIntent.create(
      amount: (total_price * 100).to_i,
      customer: current_user.stripe_id,
      payment_method: payment_method,
      currency: 'usd',
      shipping: {
        address: {
          line1: shipping_details.address_line1,
          city: shipping_details.city,
          country: shipping_details.country,
          line2: shipping_details.address_line2,
          postal_code: shipping_details.postal_code,
          state: shipping_details.state,
        },
        name: shipping_details.name
      }
    )
    payment_intent
  else
    payment_intent = Stripe::PaymentIntent.create(
      amount: (total_price * 100).to_i,
      payment_method: payment_method,
      currency: 'usd',
      shipping: {
        address: {
          line1: shipping_details.address_line1,
          city: shipping_details.city,
          country: shipping_details.country,
          line2: shipping_details.address_line2,
          postal_code: shipping_details.postal_code,
          state: shipping_details.state,
        },
        name: shipping_details.name
      }
    )
    payment_intent
  end
end