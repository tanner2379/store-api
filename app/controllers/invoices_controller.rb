class InvoicesController < ApplicationController
  def index
    @invoices = Invoice.all.reverse

    render json: @invoices
  end

  def shipping_form
    @invoice = Invoice.find(params[:invoice])
    respond_to do |format|
      format.js {render partial: 'invoices/shipping_form' }
    end
  end

  def shipped
    invoice = Invoice.find(params[:invoice_id]);
    invoice.shipping_company = params[:shipping_company];
    invoice.tracking_number = params[:tracking_number];
    invoice.shipped_date = DateTime.now();
    
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
end