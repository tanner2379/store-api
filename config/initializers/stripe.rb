Rails.configuration.stripe = {

  :publishable_key => Rails.application.credentials.send(Rails.env)[:stripe][:publishable_key],
  
  :secret_key => Rails.application.credentials.send(Rails.env)[:stripe][:secret_key]
  
  }
  
Stripe.api_key = Rails.configuration.stripe[:secret_key]