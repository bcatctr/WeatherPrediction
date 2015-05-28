require 'matrix'
class LocationPrediction < ActiveRecord::Base
  belongs_to :location
  #--------------RSquared Calculation-------------#
  def self.average(array)
    return array.inject {|sum,x| sum +=x }/ array.size.to_f
  end

  def self.total_sum_of_square(array)
    y_average = average(array)
    sst = array.map{|y| (y - y_average.round(2))**2}.inject(0, :+)
    return sst
  end

  def self.residual_sum_of_square(fy,ys)
    diff = fy.zip(ys).map { |x, y| (y - x)**2 }
    ssr = diff.inject{|sum,b| sum+b}.round(2)
    return ssr
  end

  def self.r_squared(fy, ys)
    rsquared = 1 - residual_sum_of_square(fy,ys)/total_sum_of_square(ys).to_f
    if(total_sum_of_square(ys)==0&&residual_sum_of_square(fy,ys)<0.00001)
      rsquared=1
    end
    return rsquared
  end

  #--------------Linear Regression-------------#
  # compute the coeffecients of linear regrssion
  def self.linear xs, ys, x
    x_data = xs.map { |x_i| (0..1).map { |pow| (x_i**pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(ys)
    linear_coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
    linear_coefficients.collect!{|x| x}
    y=linear_coefficients[1]*x+linear_coefficients[0]
    return "#{linear_coefficients[1]}x + #{linear_coefficients[0]}", linear_coefficients,y
  end

  # compute the coefficient of determination for linear regression
  def self.linear_rsquared (xs, ys, x)
    f_y = []
    coefficient = linear(xs, ys,x)[1]
    xs.each do |x|
      y_value = coefficient[1]*x+coefficient[0]
      f_y.push (y_value)
    end
    rsquared = r_squared(f_y,ys)
    return rsquared
  end

  #---------------Polynomial-------------#
  def self.polynomial (xs, ys, x)
    coefficients = []
    y_diff = []
    f_y = []

    # compute the coeffecients of polynomial regrssion within the range
    # store coeffeicients of each degree to one array
    for degree in (2..10)
      begin
        x_data = xs.map { |x_i| (0..degree).map { |pow| (x_i**pow).to_f } }
        mx = Matrix[*x_data]
        my = Matrix.column_vector(ys)
        @poly_coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
        #@poly_coefficients.collect!{|x| x}
        coefficients[degree-2]= @poly_coefficients
      rescue
        for i in(0..degree)
          coefficients[degree-2][i]=0
        end
      end
    end

    # compute the y value from the equation obtained from the regression
    # store all values in a two dimensional array,
    # i.e., two degree regression stored in array[0]
    coefficients.each_index do |i|
      subarray = coefficients[i]
      sum_coefficient = []
      xs.each do |x|
        sum =0
        subarray.each_index do |j|
          y_value = coefficients[i][j]*(x**j)
          sum +=y_value
        end
        sum_coefficient.push(sum)
      end
      f_y.push(sum_coefficient)
    end

    # compute the coefficient of determination
    # and find the maximum r-squared value within the range
    f_y.each_index do |i|
      sub = f_y[i]
      rsquared = r_squared(sub, ys)
      y_diff.push(rsquared)
    end
    polynomial_rsquared = y_diff.max
    index = y_diff.rindex(polynomial_rsquared)


    # output the polynomial of best fit
    result=0
    output = []
    coefficients[index].each_index do |i|
      unless coefficients[index][i] == 0
        if i == 0
          output[0] = "#{coefficients[index][i]}"
          result+=coefficients[index][i]
        elsif i == 1
          output[1] = "#{coefficients[index][i]}x"
          result+=coefficients[index][i]*x
        else
          output[i] = "#{coefficients[index][i]}x^#{i}"
          result+=coefficients[index][i]*x**i
        end
      else
      end
    end
    output.compact!
    output.reverse!
    output = output.join(" + ")

    return output,polynomial_rsquared, result
  end

  #-------------Logarithmic Regression--------------#
  # compute the coeffecients of logarithmic regrssion
  def self.logarithmic (xs, ys, x)
    log_xs = xs.map { |a| Math.log(a) }
    x_data = log_xs.map { |b_i| (0..1).map { |pow| (b_i**pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(ys)
    log_coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
    log_coefficients.collect!{|x| x}
    y=log_coefficients[1]*Math.log(x)+log_coefficients[0]

    return "#{log_coefficients[1]}*ln(x) + #{log_coefficients[0]}",log_coefficients,y
  end

  # compute the coefficient of determination for logarithmic regression
  def self.logarithmic_rsquared (xs, ys, x)
    f_y = []
    coefficient = logarithmic(xs, ys, x)[1]
    xs.each do |i|
      y_value = coefficient[1]*Math.log(i)+coefficient[0]
      f_y.push (y_value)
    end
    return r_squared(f_y,ys)
  end

  #---------------Exponential Regression---------------#
  # compute the coeffecients of exponential regrssion
  def self.exponential (xs, ys, x)
    log_ys = ys.map { |y| Math.log(y) }
    x_data = xs.map { |x_i| (0..1).map { |pow| (x_i**pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(log_ys)
    @exp_coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
    b = @exp_coefficients[1]
    a = Math.exp(@exp_coefficients[0])
    y = a*Math.exp(b*x)
    return "#{a}*e^#{b}x", a, b, y

  rescue Exception
    return "Cannot perform exponential regression on this data"
  end

  # compute the coefficient of determination for exponential regression
  def self.exponential_rsquared (xs, ys, x)
    f_y = []
    a= exponential(xs, ys, x)[1]
    b= exponential(xs, ys, x)[2]
    xs.each do |x|
      y_value = a*Math.exp(b*x)
      f_y.push (y_value)
    end
    return r_squared(f_y,ys)

  rescue Exception
    return -Float::INFINITY
  end

  # compare r-squared values for different regression methods
  # the regression method with the larger value fits the data model better
  def self.find_best_fit(xs,ys,x)
    rsquared_all = [linear_rsquared(xs, ys, x), polynomial(xs, ys, x)[1], logarithmic_rsquared(xs,ys,x), exponential_rsquared(xs,ys,x)]

    index = rsquared_all.rindex(rsquared_all.max)
    case index
      when 0
        return linear(xs, ys, x)[2],rsquared_all[0]
      when 1
        return polynomial(xs, ys, x)[2],rsquared_all[1]
      when 2
        return logarithmic(xs, ys, x)[2],rsquared_all[2]
      else
        return exponential(xs, ys, x)[3],rsquared_all[3]
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


  def self.prediction(lat,long,period)
    latitude=lat.to_f
    longitude=long.to_f
    p=period.to_i
    temperature=[]
    rainfall_amount=[]
    wind_speed=[]
    wind_direction=[]
    history_time=[]
    now_time= Time.now
    hour=now_time.hour
    minute=now_time.min
    prediction_time=hour*60+minute+p+1
    current_time=hour*60+minute+1

    find_date=now_time.strftime("%d-%m-%Y")

    min=10000000000
    nearest_loc=[0,0]
    obj=[lat,long]
    loc=[]
    Location.all.each do |l|
      loc.push([l.lat,l.long])
    end
    loc.each do |x|
      dist=Geocoder::Calculations.distance_between(x, obj)
      if dist<min
        min=dist
        nearest_loc=x
      end
    end
    nearest_loc=Location.find_by(lat:nearest_loc[0],long:nearest_loc[1])
    find_weather= nearest_loc.weathers.where("date=?",find_date )

    find_weather.each do|i|
      t_hour=i.time.hour
      t_min=i.time.min
      history_time << t_hour*60+t_min+1
      temperature <<  i.temperature
      wind_direction << (i.windDirection==nil ? i.windDirection : (i.windDirection))
      wind_speed << (i.windSpeed==nil ? i.windSpeed : (i.windSpeed+0.0001))
      rainfall_amount << (i.rainFall==nil ? i.rainFall : (i.rainFall+0.0001))
    end
    temperature = LocationPrediction.removeNil temperature
    wind_direction = LocationPrediction.removeNil wind_direction
    wind_speed = LocationPrediction.removeNil wind_speed
    rainfall_amount = LocationPrediction.removeNil rainfall_amount
    if history_time.length==0
      history_time=[1,2]
    elsif history_time.length==1
      history_time << history_time[0]+1
    end
    temp_m=temperature.min.abs
    temperature.each_with_index{|t,i| temperature[i]=temperature[i]+temp_m+0.0001}
    wind_m=wind_direction.min.abs
    wind_direction.each_with_index{|w,i| wind_direction[i]=wind_direction[i]+wind_m+0.0001}

    periodtemp=(LocationPrediction.find_best_fit(history_time,temperature,prediction_time)[0]-temp_m).round(2)
    periodtemp=(periodtemp>0&&periodtemp<30)?periodtemp:(LocationPrediction.average temperature).round(2)
    periodtemp_rs=(LocationPrediction.find_best_fit(history_time,temperature,prediction_time)[1]).round(2)
    periodwindspeed=(LocationPrediction.find_best_fit(history_time,wind_speed,prediction_time)[0]).round(2)
    periodwindspeed=(periodwindspeed>0&&periodwindspeed<60)?periodwindspeed:(LocationPrediction.average wind_speed).round(2)
    periodwindspeed_rs=(LocationPrediction.find_best_fit(history_time,wind_speed,prediction_time)[1]).round(2)
    periodwinddir=(periodwindspeed==0)?"CALM":(Parser.windDirectionToString (LocationPrediction.find_best_fit(history_time,wind_direction,prediction_time)[0]-wind_m).round(2))
    periodwinddir_rs=(periodwindspeed==0)?periodwindspeed_rs:(LocationPrediction.find_best_fit(history_time,wind_direction,prediction_time)[1]).round(2)
    periodrain=(LocationPrediction.find_best_fit(history_time,rainfall_amount,prediction_time)[0]).abs.round(2)
    periodrain_rs=(LocationPrediction.find_best_fit(history_time,rainfall_amount,prediction_time)[1]).round(2)

    currenttemp=(LocationPrediction.find_best_fit(history_time,temperature,current_time)[0]-temp_m).round(2)
    currenttemp_rs=(LocationPrediction.find_best_fit(history_time,temperature,current_time)[1]).round(2)
    currentwindspeed=(LocationPrediction.find_best_fit(history_time,wind_speed,current_time)[0]).round(2)
    currentwindspeed_rs=(LocationPrediction.find_best_fit(history_time,wind_speed,current_time)[1]).round(2)
    currentwinddir=(currentwindspeed==0)?"CALM":(Parser.windDirectionToString (LocationPrediction.find_best_fit(history_time,wind_direction,current_time)[0]-wind_m).round(2))
    currentwinddir_rs=(currentwindspeed==0)?currentwindspeed_rs:(LocationPrediction.find_best_fit(history_time,wind_direction,current_time)[1]).round(2)
    currentrain=(LocationPrediction.find_best_fit(history_time,rainfall_amount,current_time)[0]).round(2)
    currentrain_rs=(LocationPrediction.find_best_fit(history_time,rainfall_amount,current_time)[1]).round(2)

    return @prediction_hash={"lattitude"=>lat, "longitude"=>long,  "predictions"=>
        {"0"=>
             {"time"=>now_time.strftime("%H:%M%p %d-%m-%Y").downcase,"rain"=>
                 {"value"=>currentrain,"probability"=>currentrain_rs},"temp"=>
                  {"value"=>currenttemp,"probability"=>currenttemp_rs},"wind speed"=>
                  {"value"=>currentwindspeed,"probability"=>currentwindspeed_rs},"wind direction"=>
                  {"value"=>currentwinddir,"probability"=>currentwinddir_rs}
             },
         "period"=>
             { "pretime" => "#{period}",
               "time"=>(now_time+60*p).strftime("%H:%M%p %d-%m-%Y").downcase,"rain"=>
                 {"value"=>periodrain,"probability"=>periodrain_rs},"temp"=>
                   {"value"=>periodtemp,"probability"=>periodtemp_rs},"wind speed"=>
                   {"value"=>periodwindspeed,"probability"=>periodwindspeed_rs},"wind direction"=>
                   {"value"=>periodwinddir,"probability"=>periodwinddir_rs}
             }
        }
    }
  end
end
