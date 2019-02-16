# How to use R in a rails app

The following is a 5 minute example of how to use R in a rails app! It uses the [rinruby package](https://www.rubydoc.info/gems/rinruby/2.0.3/RinRuby) and is based on [this](https://www.standardco.de/using-r-in-rails) excellent tutorial. The example app created can be found [here](http://r-in-rails.herokuapp.com/)

Create a rails app 

```bash
rails new R-in-Rails --database=postgresql
```

Add `gem 'rinruby'` to the gemfile and `bundle install`


Create a Lamborghini model (with name, price and year fields), and lamborghinis controller

```bash
rails g model Lamborghini name:string price:decimal year:integer
rails g controller lamborghinis 
```

Create and migrate the database

```bash
rake db:create
rake db:migrate
```

Now go into the rails console with `rails c` and create some entries to the table in the database

```ruby
@lamborghini = Lamborghini.new(name: "Lamborghini Veneno Roadster", price: 5000000, year: 2014)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Veneno", price: 4500000, year: 2013)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Sesto Element Concept", price: 3000000, year: 2010)
@lamborghini.save
```


Now that there is data in the database, it can be accessed through a rake task and operated on using R


(still in the rails console) create a helper function to make running R scripts easy

```ruby
require 'rinruby'

def run_r_script(script, object_to_return)

    r =  RinRuby.new # establishes a new RinRuby connection
    r.eval(script)
    return r.pull object_to_return.to_s # Be sure to return the object assigned in R script
    r.quit
    r = RinRuby.new(false)

end
```

And make a simple R script. This is several lines of R code that create some names of Lamborghini models, but the same idea can be used to run more sophisticated R code

```ruby
script = <<-DOC
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

new_lamborghinis <- c("Lamborghini Cala Concept", "Lamborghini Egoista Concept", "Lamborghini Miura Concept")

new_lamborghinis %>% return(.)

DOC
```

Now run the R script and return the results as a ruby object 

```ruby
new_lamborghinis = run_r_script(script, "new_lamborghinis")
new_lamborghinis
```


Another R object can be made and returned to the rails console

```ruby
script = <<-DOC
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

# Some unnecessarily complicated math to get prices
price_1 <- 3000000
price_2 <- { 2 ^ 21 } %>%  { . * 1.430511 } %>% ceiling
price_3 <- {96.6576 * 10.09439 * 32.35789 * 64.04574 * 1.483661} %>% round(0)
  
prices <- c(price_1, price_2, price_3)

prices %>% return(.)

DOC
```

Just as before, run the R script and return the results as a ruby object 

```ruby
prices = run_r_script(script, "prices")
prices
```

And once more for years

```ruby
script = <<-DOC
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

years <- c(1995, 2013, 2006) %>% as.integer

years %>% return(.)

DOC
```

Just as before, run the R script and return the results as a ruby object 

```ruby
years = run_r_script(script, "years")
years
```





The output of the R script can easily be moved into the database

```ruby
for i in 0..(new_lamborghinis.length-1) do 
	@lamborghini = Lamborghini.new(name: new_lamborghinis[i], price: prices[i].to_d, year: years[i])
	@lamborghini.save
end
```




### Tidying this code into a single rake task 

All of the above code can be placed into a single task. Create a file in `/tasks` called `scheduler.rake`, and wrapping all the above code between the next two code chunks:

```ruby 
desc "This task does some mathematical operations in R and moves the resulting data into a rails database. This task can be called manually but can also be scheduled using heroku scheduler"
task :lambo => :environment do


# code goes here 

#see tasks/scheduler.rake for what it should look like


end
```

Now it can be run any time with `rake lambo` locally or `heroku run rake lambo` on heroku once the app is deployed.







## Deployment

Create a new heroku app with `heroku create your_new_app_name`


To deploy the app to heroku, several things need to be configured. These are: 
* adding the bundler2 buildpack
* addingthe R buildpack (for heroku-16 stack)
* setting heroku-16 stack
* adding init.R file
* adding 1 web dyno


#### Setting buildpacks

 The buildpacks used:

1. https://github.com/virtualstaticvoid/heroku-buildpack-r.git#heroku-16
2. https://github.com/bundler/heroku-buildpack-bundler2


Set these with
```bash
heroku buildpacks:set https://github.com/virtualstaticvoid/heroku-buildpack-r.git#heroku-16
heroku buildpacks:set https://github.com/bundler/heroku-buildpack-bundler2
```

Confirm they are set correctly with `heroku buildpacks`

Note: if using `rootapp-rinruby`, the buildpacks do not have to go in any specific order, but if using `rinruby` gem, they must be in the order specifed above

#### Setting heroku stack

`heroku stack` defaults to `heroku-18`, but the `https://github.com/virtualstaticvoid/heroku-buildpack-r.git#heroku-16` buildpack requires, `heroku-16`. Set this with `heroku stack:set heroku-16`


#### Creating init.R file

Simply create a file called init.R in the app's root directory, name it `init.R`, and add whatever R code you wish to have run when the app initializes. For instance, you may wish to install some R packages.

E.g. 

```R
my_packages <- c("dplyr")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE) {
    install.packages(p)
  }
}

invisible(sapply(my_packages, install_if_missing))

```



#### Adding 1 web dyno


After `heroku run bundle install`, `heroku pg:create` and `heroku run rake db:migrate`, the app will be ready to use

However, visiting the url may result in an ([H14](https://devcenter.heroku.com/articles/error-codes#h14-no-web-dynos-running)) application error

After checking `heroku status` (returning fine), the dynos can be inspected with `heroku ps`, which may return `No dynos on <app name>`, meaning a web dyno should be assigned (a Procfile would be best)

The Procfile can be made from the app's root directory with a one liner `echo "web: bundle exec rails server -p $PORT" > Procfile`

If a web dyno stil doesn't start after pushing to heroku with `git push heroku master`, `heroku ps:scale web=1` will scale web dynos to 1

The app should now be available at the heroku url









### Further notes

#### What R objects can be pulled?

Only R vectors can be pulled; an R list cannot be pulled. See documentation [here](https://dahl.byu.edu/software/rinruby/documentation.html)

i.e. R vectors can be pulled:

```ruby
test_script = <<-DOC
l <- c("hello", "world")
return(l)
DOC
output = run_r_script(test_script, "l")
output
```

But R lists cannot be pulled:

```ruby
test_script = <<-DOC
l <- list() 
l[[1]] <- 2 
l[[2]] <- 4 
return(l)
DOC
output = run_r_script(test_script, "l")
output
```


#### Usage notes

The following demonstrates (very simply) how to generate and execute R scripts using ruby

```ruby

require 'rinruby'
r = RinRuby.new


r.eval "2 * 2"
# [4]


a = 2
r.eval "#{a} * 2"
# [4]
```

This demonstrates (very simply) how to pull data from the R interpreter back to ruby

```ruby


r.eval "a <- 22"
a = r.pull("a")

# a 
# => 22.0

```





We can get data from the database to the R interpreter like so


```ruby
years = Lamborghini.pluck(:year)
r.eval "var <- c(#{years.join(', ')}); print(var)" 
[1] 2014 2013 2010 1995 2013 2006


names = Lamborghini.pluck(:name)
r.eval "va"



```



But it will make life easier to have a method that transports the rails table column into R as a vector

```ruby


def determine_class(array)
  data_types = array.group_by(&:class).sort_by{|k, v| v.length}
  if data_types.length == 1 && data_types[0][0] == NilClass
    # This handles for the rare case of an entire column of nil values
    most_prevalent_data_type = NilClass 
  else
    # This says if NilClass happens to be the most common class, use the next most common class
    most_prevalent_data_type = data_types[0][0] == NilClass ? data_types[1][0] : data_types[0][0] 
  end
  return most_prevalent_data_type
end




def transport_column(r_var_name, array)

  most_prevalent_data_type = Transport.determine_class(array)

  if most_prevalent_data_type == String
    vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.to_s.gsub('"NA"', "NA_character_")[1..-2]
    content = 'c(' + vector_as_string + ')'
  elsif
    most_prevalent_data_type == Float || most_prevalent_data_type == BigDecimal
    vector_as_string = array.map { |e| e.nil? ? "NA" : e }
    content = 'c(' + vector_as_string.join(', ') + ')'
  elsif
    most_prevalent_data_type == Integer
    vector_as_string = array.map { |e| e.nil? ? "NA" : e }
    content = 'as.integer(c(' + vector_as_string.join(', ') + '))'
  elsif
    most_prevalent_data_type == ActiveSupport::TimeWithZone 
    vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.map { |e| e.to_s }.to_s.gsub('"NA"', "NA_character_")[1..-2]
    content = 'as.POSIXct(c(' + vector_as_string + '))'
  elsif
    most_prevalent_data_type == TrueClass || most_prevalent_data_type == FalseClass
    vector_as_string = array.map { |e| e.nil? ? "NA_character_" : e }.map { |e| e == "NA_character_" ? e : e.to_s.upcase }.to_s.gsub('"', "")[1..-2]
    content = 'as.logical(c(' + vector_as_string + '))'
  elsif 
    most_prevalent_data_type == NilClass
    vector_as_string = (["NA_character_"] * array.length).to_s.gsub('"', "")[1..-2]
    content = 'as.logical(c(' + vector_as_string + '))'
  else
    # Any data types other than those above will be moved as ruby strings to R character
    vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.map { |e| e.to_s }.to_s.gsub('"NA"', "NA_character_")[1..-2]
    content = 'c(' + vector_as_string + ')'
  end 

  output = r_var_name.to_s + " <- " + content
  # output = output + "; print(" + r_var_name.to_s + ")"
  return output
end



# Example usage

years = Lamborghini.order(:id).pluck(:year)
r.eval transport_column("years", years)
# [1] 2014 2013 2010 1995 2013 2006


names = Lamborghini.order(:id).pluck(:name)
r.eval transport_column("names", names)
# [1] "Lamborghini Veneno Roadster"       "Lamborghini Veneno"               
# [3] "Lamborghini Sesto Element Concept" "Lamborghini Cala Concept"         
# [5] "Lamborghini Egoista Concept"       "Lamborghini Miura Concept" 


some_floats = [12.234, 213.2345, 0.000234]
r.eval transport_column("some_floats", some_floats)
# [1]  12.234000 213.234500   0.000234


dates = Lamborghini.order(:id).pluck(:updated_at)
r.eval transport_column("dates", dates)
 # [1] "2019-01-29 18:18:19 AEDT" "2019-01-29 18:18:19 AEDT"
 # [3] "2019-01-29 18:18:19 AEDT" "2019-01-29 18:18:19 AEDT"


```

Or perhaps more useful still, a method that transports an entire rails table into R as an R dataframe


```ruby


def transport_dataframe(r_dataframe_name, model, connection)

  r = connection

  array_of_arrays = eval(model).column_names.map { |column| eval(model).all.order(:id).map(&column.to_sym) }
  # Note: .order(:id) means that if attributes have been edited and the ids are out of order, it will return data in correct orders

  column_names = eval(model).column_names

  # Transport each column to R interpreter
  array_of_arrays.each_with_index do |column, index|
    puts index
    r.eval Transport.transport_column(column_names[index], column) 
  end

  # Now create an R dataframe from the columns 
  output = r_dataframe_name.to_s + " <- data.frame(" + column_names.join(', ') + ", stringsAsFactors=FALSE); print(" + r_dataframe_name + ")"

  return output

end






```

Call `r.eval transport_dataframe(r_dataframe_name, model, connection)` and see that the data from the rails database is now accessible to the R environment!

```ruby

r.eval transport_dataframe("lambo", "Lamborghini", r)


#   id                              name   price year              created_at
# 1  1       Lamborghini Veneno Roadster 5000000 2014 2019-01-29 17:55:51 UTC
# 2  2                Lamborghini Veneno 4500000 2013 2019-01-29 17:55:51 UTC
# 3  3 Lamborghini Sesto Element Concept 3000000 2010 2019-01-29 17:55:51 UTC
# 4  4          Lamborghini Cala Concept 3000000 1995 2019-01-29 17:56:20 UTC
# 5  5       Lamborghini Egoista Concept 3000000 2013 2019-01-29 17:56:20 UTC
# 6  6         Lamborghini Miura Concept 3000000 2006 2019-01-29 17:56:20 UTC
#                updated_at
# 1 2019-01-29 17:55:51 UTC
# 2 2019-01-29 17:55:51 UTC
# 3 2019-01-29 17:55:51 UTC
# 4 2019-01-29 17:56:20 UTC
# 5 2019-01-29 17:56:20 UTC
# 6 2019-01-29 17:56:20 UTC


```









## Congratulations! - you can now harness the power of statistical programming language R in a production Ruby on Rails web application!


More to come...























Data sourced from [here](https://successstory.com/spendit/most-expensive-lamborghini-cars)
















