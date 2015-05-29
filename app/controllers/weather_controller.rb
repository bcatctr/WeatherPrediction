class WeatherController < ApplicationController

  # load all location in database
  def locations
    @locations=Location.all
    respond_to  do |format|
      format.html
      format.json #json format is implemented in *.json.erb file
    end
  end

  # load all the weathers and locations by postcode
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
      format.json #json format is implemented in *.json.erb file
    end
  end

  # load all the weathers in needed location
  def showByLocation
    location_id=params[:location_id]
    loc=Location.find_by(location_id:location_id)
    if loc!=nil
      @weathers=loc.weathers.where("date=?",params[:date])
      @weathers_currently = Parser.currentWeather params[:location_id]
      if @weathers==nil
        @weathers=[]
      end
    else
      @weathers=[]
      @weathers_currently={}
    end

    respond_to  do |format|
      format.html
      format.json #json format is implemented in *.json.erb file
    end
  end

end
