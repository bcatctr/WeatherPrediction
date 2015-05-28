require 'matrix'
class PostcodePrediction < ActiveRecord::Base
  belongs_to :post_code
  def self.average(array)
    return array.inject {|sum,x| sum +=x }/ array.size.to_f
  end
  def linear xs,ys,x
    x_data = xs.map {|xi| (0..1).map { |pow| (xi**pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(ys)
    coefficients=((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
    y_variance=0
    for i in (0..xs.size-1)
      y_variance += (ys[i]-(coefficients[0]+coefficients[1]*xs[i]))**2
    end
    ysum=0
    sst=0
    ys.each do|y|
      ysum+=y
    end
    yaver=ysum/ys.size
    ys.each do|yi|
      sst += (yi-yaver.round(2))**2
    end
    rsquared=1- (y_variance/sst)
    if sst==0&&y_variance<0.0001
      rsquared=1
    end
    #"#{coefficients[1].round(2)}x + #{coefficients[0].round(2)}"
    return (coefficients[1]*x+coefficients[0]).round(2) ,rsquared
  end

  def polynomial xs,ys,x
    poly=Array.new(9) {Array.new()}

    for degree in (2..10)
      begin
        x_data = xs.map {|xi| (0..degree).map { |pow| (xi**pow).to_f } }
        mx = Matrix[*x_data]
        my = Matrix.column_vector(ys)
        coefficients=((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
        #put coefficient into ploy[][]
        for i in(0..coefficients.size-1)
          poly[degree-2][i]=coefficients[i]
        end
      rescue
        for i in(0..coefficients.size-1)
          poly[degree-2][i]=0
        end
      end
    end
    ysum=0
    sst=0
    ys.each do|y|
      ysum+=y
    end
    yaver=ysum/ys.size
    ys.each do|yi|
      sst += (yi-yaver.round(2))**2
    end
    #rsquared=1-y_variance/sst
    rsquared=Array.new
    #calculate variance and put them into yr[]
    yr=Array.new(9) { |e| e =0 }
    for yr_c in(0..8)
      for xr in (0..xs.size-1)
        y_value=Array.new(xs.size) { |e| e =0 }
        for yr_s in(0..yr_c+2)
          y_value[xr]+=poly[yr_c][yr_s]*(xs[xr]**yr_s)
        end
        yr[yr_c] += (ys[xr]-y_value[xr])**2
      end
      rsquared[yr_c]=1-yr[yr_c]/sst
      if sst==0&&yr[yr_c]<0.0001
        rsquared[yr_c]=1
      end
    end

    yr_min=yr[0]
    act=0
    for num in (1..8)
      if yr_min >yr[num]
        yr_min=yr[num]
        act=num
      end
    end

    #"#{(polynomial xs,ys)[0][(polynomial xs,ys)[0].size-1-xi].round(2)}x^#{(polynomial xs,ys)[0].size-1-xi} + "
    sum=0
    for xi in (0..(poly[act].size-1 ))
      str = poly[act][poly[act].size-1-xi]*x**(poly[act].size-1-xi)
      sum +=str
    end

    return sum.round(2),rsquared[act]

  end

  def logarithmic xs,ys,x

    sylnx=0
    sy=0
    sln=0
    sln2=0
    for i in 0..xs.size-1
      sylnx += Math.log(xs[i]) * ys[i]
      sy += ys[i]
      sln += Math.log(xs[i])
      sln2 += (Math.log(xs[i]))**2
    end
    b=(xs.size*sylnx-sy*sln)/(xs.size*sln2-sln**2)
    a=(sy-b*sln)/xs.size
    y_variance=0
    for i in (0..xs.size-1)
      y_variance += (ys[i]-(a+b*Math.log(xs[i])))**2
    end
    ysum=0
    sst=0
    ys.each do|y|
      ysum+=y
    end
    yaver=ysum/ys.size
    ys.each do|yi|
      sst += (yi-yaver.round(2))**2
    end
    rsquared=1-y_variance/sst
    if sst==0&&y_variance<0.0001
      rsquared=1
    end
    #"#{b.round(2)}ln(x) + #{a.round(2)}"
    return (b*Math.log(x)+a).round(2) ,rsquared
  end

  def exponential xs,ys,x
    begin
      n=xs.size-1
      sx2y=0
      sylny=0
      sxy=0
      sxylny=0
      sy=0
      for i in 0..n
        sx2y += ((xs[i]**2)*ys[i])
        sylny += ys[i]*Math.log(ys[i])
        sxy += xs[i]*ys[i]
        sxylny += xs[i]*ys[i]*Math.log(ys[i])
        sy += ys[i]
      end

    rescue
      return "Cannot perform exponential regression on this data",Float::INFINITY
    end

    a=(sx2y*sylny-sxy*sxylny)/(sy*sx2y-sxy**2)
    b=(sy*sxylny-sxy*sylny)/(sy*sx2y-sxy**2)
    y_variance=0
    for i in (0..n)
      y_variance += (ys[i]-Math.exp(a)*Math::E**(b*xs[i]))**2
    end
    ysum=0
    sst=0
    ys.each do|y|
      ysum+=y
    end
    yaver=ysum/ys.size
    ys.each do|yi|
      sst += (yi-yaver.round(2))**2
    end
    rsquared=1-y_variance/sst
    if sst==0&&y_variance<0.001
      rsquared=1
    end
    #{Math.exp(a).round(2)}e^#{b.round(2)}x
    return  (Math.exp(a)*(Math::E**(b*x))).round(2),rsquared
  end


  def best_fit xs,ys,x
    v_linear= (linear xs,ys,x)[1]
    v_polynomial =(polynomial xs,ys,x)[1]
    v_exponential =(exponential xs,ys,x)[1]
    v_logarithmic =(logarithmic xs,ys,x)[1]

    if v_linear>=v_logarithmic && v_linear>=v_exponential && v_linear>=v_polynomial
      return linear xs,ys,x
    end
    if v_exponential>=v_linear&&v_exponential>=v_polynomial&&v_exponential>=v_logarithmic
      return exponential xs,ys,x
    end
    if v_logarithmic>=v_linear&&v_logarithmic>=v_exponential&&v_logarithmic>=v_polynomial
      return logarithmic xs,ys,x
    end
    if v_polynomial>=v_logarithmic&&v_polynomial>=v_linear&&v_polynomial>=v_exponential
      return polynomial xs,ys,x
    end

  end

  def self.removeNil array
    count=0
    sum=0
    avg=0.0001
    array.each do |a|
      if a!=nil
        sum+=a
        count+=1
      end
    end
    if(count!=0)
      avg=sum/count.to_f
    end
    array.each_with_index  do |a,i|
      if a==nil
        array[i]=avg
      end
    end
    if array.length==0
      array=[0.0001,0.0001]
    end
    if array.length==1
      array << array[0]
    end
    return array
  end

  def self.postCodePrediction(post_code,period)
    postcode=post_code.to_i
    p=period.to_i
    @find_post
    temperature=Array.new
    rain_fall=Array.new
    wind_speed=Array.new
    wind_direction=Array.new
    history_time=Array.new
    now_time= Time.now
    hour=now_time.hour
    minute=now_time.min
    prediction_time=hour*60+minute+p+1
    current_time=hour*60+minute+1
    #puts prediction_time

    find_date=now_time.strftime("%d-%m-%Y")

    if PostCode.find_by postCode_id: postcode
      @find_post=PostCode.find_by postCode_id: postcode
    else
      min=0
      mm=1000
      code=PostCode.all
      code.each do |i|
        min = (i.postCode_id.to_i-postcode).abs
        if min<mm
          mm=min
          @near_postcode=i.postCode_id
          #puts @near_postcode
        end
      end
      @find_post=PostCode.find_by postCode_id: @near_postcode
    end

    find_location= Location.find_by postCode_id: @find_post.id
    find_weather= find_location.weathers.where("date=?",find_date)

    find_weather.each do|i|
      t_hours=i.time.hour
      t_mins=i.time.min
      history_time << t_hours*60+t_mins+1

      temperature <<  i.temperature
      wind_direction << (i.windDirection==nil ? i.windDirection : (i.windDirection))
      wind_speed << (i.windSpeed==nil ? i.windSpeed : (i.windSpeed+0.0001))
      rain_fall << (i.rainFall==nil ? i.rainFall : (i.rainFall+0.0001))
    end
    temperature = PostcodePrediction.removeNil temperature
    wind_direction = PostcodePrediction.removeNil wind_direction
    wind_speed = PostcodePrediction.removeNil wind_speed
    rain_fall = PostcodePrediction.removeNil rain_fall
    if history_time.length==0
      history_time=[1,31]
    elsif history_time.length==1
      history_time << history_time[0]+31
    end
    tep_m=temperature.min.abs
    temperature.each_with_index { |t,i|  temperature[i] += (tep_m +0.0001)}
    wd_m=wind_direction.min.abs
    wind_direction.each_with_index { |t,i | wind_direction[i] += (wd_m+0.0001) }

    period_wind_speed= PostcodePrediction.new.best_fit(history_time,wind_speed,current_time)[0].abs.round(2) #wind_speed
    period_temperature=(PostcodePrediction.new.best_fit(history_time,temperature,current_time)[0]-tep_m).round(2) #temperature
    period_wind_direction=(period_wind_speed==0)?"CALM":(Parser.windDirectionToString (PostcodePrediction.new.best_fit(history_time,wind_direction,current_time)[0]-wd_m)) #wind_direction
    period_rainfall=PostcodePrediction.new.best_fit(history_time,rain_fall,current_time)[0].abs.round(2) #rainfall
    period_temp_pro=PostcodePrediction.new.best_fit(history_time,temperature,current_time)[1].round(2)
    period_ws_pro=PostcodePrediction.new.best_fit(history_time,wind_speed,current_time)[1].round(2)
    period_rain_pro=PostcodePrediction.new.best_fit(history_time,rain_fall,current_time)[1].round(2)
    period_wdd_pro= (period_wind_speed==0)?period_ws_pro:(PostcodePrediction.new.best_fit(history_time,wind_direction,current_time)[1]).round(2)

    prediction_wind_speed=PostcodePrediction.new.best_fit(history_time,wind_speed,prediction_time)[0].abs.round(2)
    prediction_wind_speed=(prediction_wind_speed>0&&prediction_wind_speed<60)?prediction_wind_speed:(PostcodePrediction.average wind_speed)
    prediction_temperature=(PostcodePrediction.new.best_fit(history_time,temperature,prediction_time)[0]-tep_m).round(2)
    prediction_temperature=(prediction_temperature>0&&prediction_temperature<30)?prediction_temperature:(PostcodePrediction.average temperature)
    prediction_wind_direction=(period_wind_speed==0)?"CALM":(Parser.windDirectionToString (PostcodePrediction.new.best_fit(history_time,wind_direction,prediction_time)[0]-wd_m))
    prediction_rainfall=PostcodePrediction.new.best_fit(history_time,rain_fall,prediction_time)[0].abs.round(2)
    predic_temp_pro=PostcodePrediction.new.best_fit(history_time,temperature,prediction_time)[1].round(2)
    perdic_ws_pro=PostcodePrediction.new.best_fit(history_time,wind_speed,prediction_time)[1].round(2)
    perdic_rain_pro=PostcodePrediction.new.best_fit(history_time,rain_fall,prediction_time)[1].round(2)
    predic_wdd_pro= (period_wind_speed==0)?perdic_ws_pro:(PostcodePrediction.new.best_fit(history_time,wind_direction,prediction_time)[1]).round(2)

    return @prediction={ "location_id" =>find_location.location_id, "predictions"=>
        {"0"=>
             {"time"=>now_time.strftime("%H:%M%p %d-%m-%Y").downcase,"rain"=>
                 {"value"=>period_rainfall,"probability"=>period_rain_pro},"temp"=>
                  {"value"=>period_temperature,"probability"=>period_temp_pro},"wind speed"=>
                  {"value"=>period_wind_speed,"probability"=>period_ws_pro},"wind direction"=>
                  {"value"=>period_wind_direction,"probability"=>period_wdd_pro}
             },
         "period"=>
             {  "pretime"=>"#{p}",
                "time"=>(now_time+60*p).strftime("%H:%M%p %d-%m-%Y").downcase, "rain"=>
                 {"value"=>prediction_rainfall,"probability"=>perdic_rain_pro },"temp"=>
                    {"value"=>prediction_temperature,"probability"=>predic_temp_pro},"wind speed"=>
                    {"value"=>prediction_wind_speed,"probability"=>perdic_ws_pro},"wind direction"=>
                    {"value"=>prediction_wind_direction,"probability"=>predic_wdd_pro}
             }
        }}
  end
end
