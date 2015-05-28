class PredictionController < ApplicationController
  def predictionByPostcode
    post_code= params[:post_code]
    period=params[:period]
    @p= PostcodePrediction.postCodePrediction(post_code,period)
    respond_to  do |format|
      format.html
      format.json
    end
  end

  def predictionByLocation
    latitude= params[:lat]
    longitude= params[:long]
    period=params[:period]
    @p= LocationPrediction.prediction(latitude,longitude,period)
    respond_to  do |format|
      format.html
      format.json
    end
  end
end
