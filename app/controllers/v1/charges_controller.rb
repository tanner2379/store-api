class V1::ChargesController < V1::ApiController

  def new
    if user_signed_in?
      @shippingOptions = @current_user.shipping_options
      @paymentOptions = @current_user.payment_options

      render json: {
        shippingOptions: @shippingOptions,
        paymentOptions: @paymentOptions
      }
    else
      render json: {
        shippingOptions: nil,
        paymentOptions: nil
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
      order = Order.create(invoice: invoice, product: cartItem.product, quantity: cartItem.quantity)
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
      @cart_items.append(cart_item);
      total_price += cart_item.total_price;
    end

    shipping_details = nil;

    if params[:shipping_details] && params[:shipping_details] != ""
      shipping_details = ShippingAddress.find(params[:shipping_details])
    else
      shipping_details = ShippingAddress.new(
        name: params[:name],
        address_line1: params[:address_line1],
        address_line2: params[:address_line2],
        city: params[:city],
        state: params[:state],
        country: params[:country],
        postal_code: params[:postal_code]
      )

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

    if params[:payment_method] && params[:payment_method] != ""
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

          if !last4_match
            payment_method = Stripe::PaymentMethod.create({
              type: 'card',
              card: {
                number: payment[:card_number],
                exp_month: payment[:card_expires_month],
                exp_year: payment[:card_expires_year],
                cvc: payment[:card_cvv],
              },
            })

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
                status: 200
              }
            else
              render json: {
                status: 500
              }
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
            if @payment_intent
              render json: {
                payment_intent: @payment_intent['id'],
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
          if @payment_intent
            render json: {
              payment_intent: @payment_intent['id'],
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