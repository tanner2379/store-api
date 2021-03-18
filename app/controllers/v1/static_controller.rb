class V1::StaticController < V1::ApiController
  def home
    render json: {status: "Its Working!!!"}
  end
end