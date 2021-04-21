class V1::ChargesController < V1::ApiController

  def new
    if user_signed_in?
      @shippingOptions = @current_user.shipping_options
      @paymentOptions = @current_user.payment_options
      @cart_items = CartItem.where(user_id: @current_user.id).map {|cart_item| cart_item.id}

      render json: {
        shippingOptions: @shippingOptions,
        paymentOptions: @paymentOptions,
        cartItems: @cart_items
      }
    else
      @cart_items = []
      if cookies.encrypted[:cart_tracker]
        @cart_items = CartItem.where(session_id: cookies.encrypted[:cart_tracker]).map {|cart_item| cart_item.id}
      end

      render json: {
        shippingOptions: nil,
        paymentOptions: nil,
        cartItems: @cart_items
      }
    end
  end

  def index

  end

  def success
    @payment_intent = params[:payment_intent]
    @cart_items = []
    params[:cart_items].each do |cart_item_id|
      @cart_items.append(CartItem.find(cart_item_id))
    end
    # item_ids = params[:item_ids]
    
    # item_ids.each do |item_id|
    #   CartItem.find(item_id).destroy
    # end

  end

  def cancel

  end

  def confirm
    payment_intent = Stripe::PaymentIntent.retrieve(params[:payment_intent]);
    
    Stripe::PaymentIntent.confirm(
      params[:payment_intent],
      {payment_method: payment_intent.payment_method},
    )

    shipping_address = ShippingAddress.where(name: payment_intent.shipping.name, address_line1: payment_intent.shipping.address.line1).first

    invoice = Invoice.new(shipping_address: shipping_address)
    params[:cart_items].each do |cart_item_id|
      cartItem = CartItem.find(cart_item_id)
      product = cartItem.product
      new_stock = product.in_stock - cartItem.quantity
      product.update!(in_stock: new_stock)
      order = Order.create(invoice: invoice, product_id: product.id, product_name: product.name, product_price: product.price, quantity: cartItem.quantity)
      invoice.orders << order
      cartItem.destroy
    end

    if invoice.save
      render json: {
        status: 200
      }
    else
      render json: {
        status: 500
      }
    end
  end

  def create
    cart_item_ids = params[:cart_items];
    @cart_items = [];
    total_price = 0;

    cart_item_ids.each do |cart_item_id|
      cart_item = CartItem.find(cart_item_id);
      if cart_item.quantity == 0
        cart_item.destroy
      end
      @cart_items.append(cart_item);
      total_price += cart_item.total_price;
    end

    shipping_details = nil;

    if params[:shipping_details] && params[:shipping_details] != "" && params[:shipping_details] != "Select Saved Address"
      shipping_details = ShippingAddress.find(params[:shipping_details])
    else
      if params[:billing_as_shipping]
        shipping_details = ShippingAddress.find_or_create_by(
          name: params[:billing_name],
          address_line1: params[:billing_address_line1],
          address_line2: params[:billing_address_line2],
          city: params[:billing_city],
          state: params[:billing_state],
          country: params[:billing_country],
          postal_code: params[:billing_postal_code]
        )
      else
        shipping_details = ShippingAddress.find_or_create_by(
          name: params[:name],
          address_line1: params[:address_line1],
          address_line2: params[:address_line2],
          city: params[:city],
          state: params[:state],
          country: params[:country],
          postal_code: params[:postal_code]
        )
      end

      if user_signed_in?
        address_match = false
        @current_user.shipping_addresses.each do |address|
          if address.address_line1 == shipping_details.address_line1
            address_match = true
          end
        end

        if !address_match
          shipping_details.user_id = @current_user.id
          shipping_details.save
        end
      else
        shipping_details.save
      end   
    end

    if params[:payment_method] && params[:payment_method] != "" && params[:payment_method] != "Select Saved Payment Method"
      payment_method = PaymentMethod.find(params[:payment_method])

      if payment_method.expired?
        render json: {
          warning: 'Payment Method Expired',
          status: 500
        }
      else
        @payment_intent = create_payment(total_price, payment_method.stripe_id, shipping_details)
        if @payment_intent
          render json: {
            payment_intent: @payment_intent['id'],
            name: @payment_intent['shipping']['name'],
            shipping: @payment_intent['shipping']['address'],
            last_four: payment_method.last4,
            cart_items: @cart_items,
            status: 200
          }
        else
          render json: {
            status: 500
          }
        end
      end
    else
      payment = {
        card_number: params[:card_number],
        card_cvv: params[:card_cvv],
        card_expires_month: params[:card_expires_month],
        card_expires_year: params[:card_expires_year]
      }
      if validate_payment(payment)   
        if user_signed_in?
          last4_match = false
          @current_user.payment_methods.each do |payment_method|
            if payment[:card_number].include?(payment_method.last4)
              last4_match = true
              break
            end
          end

          payment_method = nil
          if !last4_match
            if params[:billing_email] != ""
              payment_method = Stripe::PaymentMethod.create({
                type: 'card',
                card: {
                  number: payment[:card_number],
                  exp_month: payment[:card_expires_month],
                  exp_year: payment[:card_expires_year],
                  cvc: payment[:card_cvv],
                },
                billing_details: {
                  address: {
                    city: params[:billing_city],
                    country: params[:billing_country],
                    line1: params[:billing_address_line1],
                    line2: params[:billing_address_line2],
                    postal_code: params[:billing_postal_code],
                    state: params[:billing_state]
                  },
                  email: params[:billing_email],
                  name: params[:billing_name],
                }
              })
            else
              payment_method = Stripe::PaymentMethod.create({
                type: 'card',
                card: {
                  number: payment[:card_number],
                  exp_month: payment[:card_expires_month],
                  exp_year: payment[:card_expires_year],
                  cvc: payment[:card_cvv],
                },
                billing_details: {
                  address: {
                    city: params[:billing_city],
                    country: params[:billing_country],
                    line1: params[:billing_address_line1],
                    line2: params[:billing_address_line2],
                    postal_code: params[:billing_postal_code],
                    state: params[:billing_state]
                  },
                  name: params[:billing_name],
                }
              })
            end

            if !@current_user.stripe_id
              customer = Stripe::Customer.create(email: @current_user.email, payment_method: payment_method,
                                                  invoice_settings: {default_payment_method: payment_method,},)
              @current_user.stripe_id = customer.id
              @current_user.save
            end

            pm = PaymentMethod.new(stripe_id: payment_method.id, user_id: @current_user.id)
            pm.save

            @payment_intent = create_payment(total_price, payment_method.id, shipping_details)
            if @payment_intent
              render json: {
                payment_intent: @payment_intent['id'],
                name: @payment_intent['shipping']['name'],
                shipping: @payment_intent['shipping']['address'],
                last_four: payment_method.card.last4,
                cart_items: @cart_items,
                status: 200
              }
            else
              render json: {
                status: 500
              }
            end
          else
            if params[:billing_email] != ""
              payment_method = Stripe::PaymentMethod.create({
                type: 'card',
                card: {
                  number: payment[:card_number],
                  exp_month: payment[:card_expires_month],
                  exp_year: payment[:card_expires_year],
                  cvc: payment[:card_cvv],
                },
                billing_details: {
                  address: {
                    city: params[:billing_city],
                    country: params[:billing_country],
                    line1: params[:billing_address_line1],
                    line2: params[:billing_address_line2],
                    postal_code: params[:billing_postal_code],
                    state: params[:billing_state]
                  },
                  email: params[:billing_email],
                  name: params[:billing_name],
                }
              })
            else
              payment_method = Stripe::PaymentMethod.create({
                type: 'card',
                card: {
                  number: payment[:card_number],
                  exp_month: payment[:card_expires_month],
                  exp_year: payment[:card_expires_year],
                  cvc: payment[:card_cvv],
                },
                billing_details: {
                  address: {
                    city: params[:billing_city],
                    country: params[:billing_country],
                    line1: params[:billing_address_line1],
                    line2: params[:billing_address_line2],
                    postal_code: params[:billing_postal_code],
                    state: params[:billing_state]
                  },
                  name: params[:billing_name],
                }
              })
            end
            @payment_intent = create_payment(total_price, payment_method.id, shipping_details)
            if @payment_intent
              render json: {
                payment_intent: @payment_intent['id'],
                name: @payment_intent['shipping']['name'],
                shipping: @payment_intent['shipping']['address'],
                last_four: payment_method.card.last4,
                cart_items: @cart_items,
                status: 200
              }
            else
              render json: {
                status: 500
              }
            end
          end
        else
          payment_method = Stripe::PaymentMethod.create({
            type: 'card',
            card: {
              number: payment[:card_number],
              exp_month: payment[:card_expires_month],
              exp_year: payment[:card_expires_year],
              cvc: payment[:card_cvv],
            },
          })
          @payment_intent = create_payment(total_price, payment_method.id, shipping_details)

          if params[:create_account] && !User.exists?(email: params[:billing_email])
            customer = Stripe::Customer.create(email: params[:billing_email], payment_method: payment_method,
              invoice_settings: {default_payment_method: payment_method,},)
            User.create!(name: params[:billing_name], email: params[:billing_email], password: params[:password], password_confirmation: params[:password_confirmation], stripe_id: customer.id )
          end

          if @payment_intent
            render json: {
              payment_intent: @payment_intent['id'],
              name: @payment_intent['shipping']['name'],
              shipping: @payment_intent['shipping']['address'],
              last_four: payment_method.card.last4,
              status: 200
            }
          else
            render json: {
              status: 500
            }
          end
        end
      end
    end
  end
end