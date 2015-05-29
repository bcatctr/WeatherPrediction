ORIGINAL_URL = 'http://www.bom.gov.au/vic/observations/vicall.shtml'
API_KEY = 'd48db2413a23d23463d9b9a06d3f5ec1'
FORECAST_URL = 'https://api.forecast.io/forecast'
require 'nokogiri'
require 'open-uri'
require 'geocoder'
require 'json'

# set up the hash storing the pre-rainfall, this is used to calculate the precipitation
$pre_rainfallAmount=Hash.new
Location.all.each do |l|
  $pre_rainfallAmount.merge!(l.id=>[0.0,0])
end

class Parser < ActiveRecord::Base
  # used to scrap all the weather data from BOM for the locations in database
  def self.jsonParsing
    doc = Nokogiri::HTML(open(ORIGINAL_URL))
    # doc1 store all the weathers for locations whose data are refreshed every 30 minutes
    doc1 = doc.css('tr.rowleftcolumn')
    # doc2 store all the weathers for locations where no observation is available within the last 75 minutes
    doc2 = doc.css('tr.contrast')
    doc1.each do |d|
      name=d.css('th a').children.to_s
      loc=Location.find_by(location_id:name)
      if(loc!=nil)
        weather=Weather.new
        weather.location=loc
        time_string=d.css("td[headers*='-datetime']").children.to_s.split('/')
        day = time_string[0]
        time_string = time_string[1].split(':')
        hour = time_string[0].to_i
        if time_string[1].include? 'pm'
          hour+=12
          if hour==24
            hour=12
          end
        else
          if hour==12
            hour=0
          end
        end
        second = time_string[1].scan(/\d\d/)[0]
        weather.time=Time.utc(Time.now.year,Time.now.month,day,hour,second)
        # the repeat weather record is obviated
        if loc.weathers.find_by(time:weather.time)==nil
          weather.date = weather.time.strftime("%d-%m-%Y")
          temperature=d.css("td[headers*='-tmp']").children.to_s
          if temperature!='-'
            weather.temperature=temperature.to_f
          end
          windSpeed=d.css("td[headers*='-wind-spd-kmh']").children.to_s
          if windSpeed!='-'
            weather.windSpeed=windSpeed.to_f
          end
          windDir=self.windDirectionToFloat d.css("td[headers*='-wind-dir']").children.to_s
          if windDir!=-2
            weather.windDirection=windDir
          end
          rainFall=d.css("td[headers*='-rainsince9am']").children.to_s
          # the rainfall is calculated by get the difference from two near record and
          # muitiply by 2
          if rainFall!='-'&&rainFall!='Trace'
            weather.rainFall=(rainFall.to_f-$pre_rainfallAmount[loc.id][0])*2
            if($pre_rainfallAmount[loc.id][1]==0)
              weather.rainFall=0.0
              $pre_rainfallAmount[loc.id][1]=1
            end
            $pre_rainfallAmount[loc.id][0]=rainFall.to_f
          else
            $pre_rainfallAmount[loc.id][0]=0.0
            $pre_rainfallAmount[loc.id][1]=0
          end
          weather.created_at=Time.utc(*Time.new.to_a)
          weather.updated_at=Time.utc(*Time.new.to_a)
          weather.save
        end
      end
    end
    doc2.each do |d|
      name=d.css('th a').children.to_s
      loc=Location.find_by(location_id:name)
      if(loc!=nil)
        weather=Weather.new
        weather.location=loc
        time_string=d.css("td[headers*='-datetime']").children.to_s.split('/')
        day = time_string[0]
        time_string = time_string[1].split(':')
        hour = time_string[0].to_i
        if time_string[1].include? 'pm'
          hour+=12
          if hour==24
            hour=12
          end
        else
          if hour==12
            hour=0
          end
        end
        second = time_string[1].scan(/\d\d/)[0]
        weather.time=Time.utc(Time.now.year,Time.now.month,day,hour,second)
        if loc.weathers.find_by(time:weather.time)==nil
          weather.date = weather.time.strftime("%d-%m-%Y")
          temperature=d.css("td[headers*='-tmp']").children.to_s
          if temperature!='-'
            weather.temperature=temperature.to_f
          end
          windSpeed=d.css("td[headers*='-wind-spd-kmh']").children.to_s
          if windSpeed!='-'
            weather.windSpeed=windSpeed.to_f
          end
          windDir=self.windDirectionToFloat d.css("td[headers*='-wind-dir']").children.to_s
          if windDir!=-2
            weather.windDirection=windDir
          end
          rainFall=d.css("td[headers*='-rainsince9am']").children.to_s
          if rainFall!='-'&&rainFall!='Trace'
            weather.rainFall=(rainFall.to_f-$pre_rainfallAmount[loc.id][0])*2
            if($pre_rainfallAmount[loc.id][1]==0)
              weather.rainFall=0.0
              $pre_rainfallAmount[loc.id][1]=1
            end
            $pre_rainfallAmount[loc.id][0]=rainFall.to_f
          else
            $pre_rainfallAmount[loc.id][0]=0.0
            $pre_rainfallAmount[loc.id][1]=0
          end
          weather.created_at=Time.utc(*Time.new.to_a)
          weather.updated_at=Time.utc(*Time.new.to_a)
          weather.save
        end
      end
    end
  end

  # scape all the locations including their longitude and latitude from BOM
  def self.locationScraping
    doc = Nokogiri::HTML(open(ORIGINAL_URL))
    url_base = doc.css('th a').to_a
    urls = url_base.map { |link| "http://www.bom.gov.au#{link['href']}"}
    urls.each  do |url|
      d = Nokogiri::HTML(open(url))
      names = d.to_s.scan(/<h1>Latest Weather Observations for [[[:alpha:]][[:blank:]]()]{3,}/)
      name = names[0].split(" for ")[1].strip
      #the repeat location is obviated
      if Location.find_by(location_id:name)==nil
        s = d.css("[class='stationdetails']").to_s
        location = s.scan(/-?\d{2,3}\.\d{2,3}/)
        #names = s.scan(/<b>Name:<\/b>.+<\/td>/)
        #name=names[0].scan(/[[[:alpha:]][[:blank:]]]{3,}/)[1].strip
        a = Geocoder.search(location[0]+","+location[1])
        post = a.first.postal_code.to_i
        lat=location[0].to_f
        long=location[1].to_f
        # ignore if the location has no postcode
        if post!=0
          postcode=PostCode.find_by(postCode_id:post)
          if postcode==nil
            postcode = PostCode.create(postCode_id:post)
          end
          newLocation = Location.create(location_id:name,lat:lat,long:long,postCode_id:postcode.id,created_at:Time.utc(*Time.new.to_a),updated_at:Time.utc(*Time.new.to_a))
        end
      end
    end
  end

  # forecast.io is just used to give the current temperature and condition
  # in GET /weather/data/:location_id/:date
  def self.currentWeather name
    loc=Location.find_by(location_id:name)
    lat_long=loc.lat.to_s+","+loc.long.to_s
    forecast = JSON.parse(open("#{FORECAST_URL}/#{API_KEY}/#{lat_long}").read)
    current=forecast["currently"]
    return {"temperature"=>((current["temperature"]-32)/1.8).round(2),"condition"=>current["summary"]}
  end

  # transform the wind direction from symbol to float which is used in regression
  def self.windDirectionToFloat windDir
    case windDir
      when "N"
        return 0
      when "NNE"
        return 22.5
      when "NE"
        return 45
      when "ENE"
        return 67.5
      when "E"
        return 90
      when "ESE"
        return 112.5
      when "SE"
        return 135
      when "SSE"
        return 157.5
      when "S"
        return 180
      when "SSW"
        return 202.5
      when "SW"
        return 225
      when "WSW"
        return 247.5
      when "W"
        return 270
      when "WNW"
        return 292.5
      when "NW"
        return 315
      when "NNW"
        return 337.5
      when "CALM"
        return -1   #show the wind direction is calm
      else
        return -2   #show the wind direction is '-'
    end
  end

  # transform the wind direction from float to symbol which is used in representation
  def self.windDirectionToString windDir
    if windDir!=nil
      windDir=windDir<0?windDir:windDir%360
      if (windDir>=0&&windDir<=11.25)||(windDir>=348.75&&windDir<=360)
        return "N"
      elsif windDir>=11.25&&windDir<=33.75
        return "NNE"
      elsif windDir>33.75&&windDir<=56.25
        return "NE"
      elsif windDir>56.25&&windDir<=78.75
        return "ENE"
      elsif windDir>78.75&&windDir<=101.25
        return "E"
      elsif windDir>101.25&&windDir<=123.75
        return "ESE"
      elsif windDir>123.75&&windDir<=146.25
        return "SE"
      elsif windDir>146.25&&windDir<=168.75
        return "SSE"
      elsif windDir>168.75&&windDir<=191.25
        return "E"
      elsif windDir>191.25&&windDir<=213.75
        return "SSW"
      elsif windDir>213.75&&windDir<=236.25
        return "SW"
      elsif windDir>236.25&&windDir<=258.25
        return "WSW"
      elsif windDir>258.75&&windDir<=281.25
        return "W"
      elsif windDir>281.25&&windDir<=303.75
        return "WNW"
      elsif windDir>303.75&&windDir<=326.25
        return "NW"
      elsif windDir>326.25&&windDir<348.75
        return "NNW"
      else
        return "CALM"
      end
    else
      return "-"
    end
  end
end
