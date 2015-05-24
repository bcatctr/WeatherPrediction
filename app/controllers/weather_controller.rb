class WeatherController < ApplicationController

  def locations
    @locations=Location.all
    respond_to  do |format|
      format.html
      format.json
    end
  end

  def showByPostcode

  end

  def showByLocation

  end
end
