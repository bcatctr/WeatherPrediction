class WeatherController < ApplicationController

  def locations
    @locations=Location.all
    respond_to  do |format|
      format.html
      format.json
    end
  end

  def showByPostcode
    postcode = params[:post_code]
    date = params[:date]

  end

  def showByLocation
    location_id=params[:location_id]
    loc=Location.find_by(location_id:location_id)
    @weathers=loc.weathers.where("date=?",params[:date])
  end
end
