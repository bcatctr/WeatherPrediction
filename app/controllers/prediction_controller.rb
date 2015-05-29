class PredictionController < ApplicationController
  # this function is used to predict by post code by calling
  # modal PostcodePediction
  def predictionByPostcode
    post_code= params[:post_code]
    period=params[:period]
    @p= PostcodePrediction.postCodePrediction(post_code,period)
    respond_to  do |format|
      format.html
      format.json #json format is implemented in *.json.erb file
    end
  end

  # this function is used to predict by longitude and latitude by calling
  # modal LocationPrediction
  def predictionByLocation
    latitude= params[:lat]
    longitude= params[:long]
    period=params[:period]
    @p= LocationPrediction.prediction(latitude,longitude,period)
    respond_to  do |format|
      format.html
      format.json #json format is implemented in *.json.erb file
    end
  end
end
