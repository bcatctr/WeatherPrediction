class WeatherController < ApplicationController

  def locations
    @locations=Location.all
    respond_to  do |format|
      format.html
      format.json
    end
  end

  def showByPostcode
    postcode = PostCode.find_by(postCode_id:params[:post_code].to_i)
    date = params[:date]
    if postcode!=nil
      @locations=Location.where("postCode_id=?",postcode)
    else
      @locations=[]
    end
    respond_to  do |format|
      format.html
      format.json
    end
  end

  def showByLocation
    location_id=params[:location_id]
    loc=Location.find_by(location_id:location_id)
    @weathers=loc.weathers.where("date=?",params[:date])
    @weathers_currently = Parser.currentWeather params[:location_id]
    respond_to  do |format|
      format.html
      format.json
    end
  end
end
