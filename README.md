# How to use R in a rails app

The following is a 5 minute example of how to use R in a rails app! It uses the [rinruby package](https://www.rubydoc.info/gems/rinruby/2.0.3/RinRuby) and is based on [this](https://www.standardco.de/using-r-in-rails) excellent tutorial. The example app created can be found [here](http://r-in-rails.herokuapp.com/)

Create a rails app 

```bash
rails new R-in-Rails --database=postgresql
```

Add `gem 'rinruby'` to the gemfile and `bundle install`


Create a Vegetable model (with name and weight fields), and vegetables controller

```bash
rails g model Vegetable name:string weight:decimal 
rails g controller vegetables 
```

Create and migrate the database

```bash
rake db:create
rake db:migrate
```

Now go into the rails console..

```bash
rails c
```

..and create some entries to the table in the database

```ruby
@vegetable = Vegetable.new(name: "Brocolli", weight: 550)
@vegetable.save

@vegetable = Vegetable.new(name: "Carrots", weight: 1000)
@vegetable.save

@vegetable = Vegetable.new(name: "Red Pepper", weight: 200)
@vegetable.save
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

And make a simple R script

```ruby
script = <<-DOC
install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

new_vegetables <- c("Garlic", "Ginger", "Bok Choy")

new_vegetables %>% return(.)

DOC
```

Now run the R script and return the results as a ruby object 

```ruby
new_vegetables = run_r_script(script, "new_vegetables")
new_vegetables
```


Another R object can be made and returned to the rails console

```ruby
script = <<-DOC
# Note: not necessary to run install.packages every time, just the first
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

weights <- 20 %>% { 3 * . } %>% { . * c(1,2,3) }

weights %>% return(.)

DOC
```

Just as before, run the R script and return the results as a ruby object 

```ruby
weights = run_r_script(script, "weights")
weights
```


The output of the R script can easily be moved into the database

```ruby
for i in 0..(new_vegetables.length-1) do 
	@vegetable = Vegetable.new(name: new_vegetables[i], weight: weights[i].to_d)
	@vegetable.save
end
```



## Deployment

All of the above code can be placed into a rake task (see `lib/tasks/example_usage.rake`), and run with `rake example:example_usage`

I have not been able to successfully deploy to heroku with the usual `git push heroku master` 

I installed the bundler2 buildpack by running `heroku buildpacks:set https://github.com/bundler/heroku-buildpack-bundler2
` (see [here](https://github.com/bundler/bundler/issues/6784) )

I then encountered an issue with compiling rake which I couldn't resolve. Running `RAILS_ENV=production bundle exec rake assets:precompile` as per [here](https://stackoverflow.com/questions/36394297/heroku-push-error-could-not-detect-rake-tasks) worked as expected in production locally, despite the deployment to heroku continuing to fail

After these remedies plus some others, still no luck. 


UPDATE

Successfully deployed by simply changing `gem 'rinruby'` to `gem 'rootapp-rinruby'`




### Some further notes

```ruby
# An R list cannot be pulled
# Only R vectors can be pulled
# Documentation here: https://dahl.byu.edu/software/rinruby/documentation.html


# Pulling an R list fails
test_script = <<-DOC
l <- list() 
l[[1]] <- 2 
l[[2]] <- 4 
return(l)
DOC
output = run_r_script(test_script)



# Pulling an R vector succeeds 
test_script = <<-DOC
l <- c("hi", "there")
return(l)
DOC
output = run_r_script(test_script)


# NOTE: don't forget to change the variable name in the script <<-DOC etc etc
```







