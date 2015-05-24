class WeatherController < ApplicationController
  def locations
    @locations=Location.all
    respond_to  do |format|
      format.html
      format.json {render json:@locations}
    end
  end
end
