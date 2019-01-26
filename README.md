# How to use R in a rails app

The following is a 5 minute example of how to use R in a rails app! It uses the [rinruby package](https://www.rubydoc.info/gems/rinruby/2.0.3/RinRuby) and is based on [this](https://www.standardco.de/using-r-in-rails) excellent tutorial. The example app created can be found [here](http://r-in-rails.herokuapp.com/)

Create a rails app 

```bash
rails new R-in-Rails --database=postgresql
```

Add `gem 'rootapp-rinruby'` to the gemfile and `bundle install`
Note: `rootapp-rinruby` is a more recent fork of `rinruby`


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




## Tidying this up 

All of the above code can be placed into a single task by creating a file in `/tasks` called `scheduler.rake`, and wrapping all the above code between the following blocks:

```ruby 
desc "This task is called by the Heroku scheduler add-on"
task :example_usage => :environment do
```

Code goes here
```ruby
end
```

Now it can be run any time with `rake example_usage` locally or `heroku run rake example_usage` on heroku.







## Deployment


To deploy the app to heroku, several things need to be configured. These are: 
* adding the bundler2 buildpack
* addingthe R buildpack (for heroku-16 stack)
* setting heroku-16 stack
* adding init.R file
* adding 1 web dyno


#### Setting buildpacks

 The buildpacks used:

1. https://github.com/bundler/heroku-buildpack-bundler2
1. https://github.com/virtualstaticvoid/heroku-buildpack-r.git#heroku-16

Set these with
```bash
heroku buildpacks:set https://github.com/bundler/heroku-buildpack-bundler2
heroku buildpacks:set https://github.com/virtualstaticvoid/heroku-buildpack-r.git#heroku-16
```

Confirm they are set correctly with `heroku buildpacks`


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

```ruby
# An R list cannot be pulled
# Only R vectors can be pulled
# Documentation here: https://dahl.byu.edu/software/rinruby/documentation.html



# R vectors can be pulled
test_script = <<-DOC
l <- c("hi", "there")
return(l)
DOC
output = run_r_script(test_script, "l")


# But R lists cannot be pulled
test_script = <<-DOC
l <- list() 
l[[1]] <- 2 
l[[2]] <- 4 
return(l)
DOC
output = run_r_script(test_script, "l")


```







