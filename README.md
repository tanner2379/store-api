# README

A really simple online store API built independently to learn how to interact with react and rails

* Ruby 2.7.0

* Rails 6.1.3

* Set your stripe API keys using rails credentials:edit in this format:
    development:
      stripe:
        publishable_key: pk_test_blablablabla
        secret_key: sk_test_blablablabla

    production:
      stripe:
        publishable_key: pk_blablbablba
        secret_key: sk_blablblbalbal
        
* Set up config/initializers/cors.rb to allow traffic from your domain/development port
* Set up config/initializers/session_store.rb to allow cookies from your domain/development port

* Database creation: rails db:create

* No current seeded data

* Test suite not yet implemented

* Job Queues not yet implemented

* Deployment instructions: on the to-do list

* ...
