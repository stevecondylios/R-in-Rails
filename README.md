# How to use R in a rails app


Create a rails app 

```bash
rails new R-in-Rails --database=postgresql
```

Before making a database, add `gem 'rinruby'` to the gemfile and `bundle install`

Create the database

```bash
rake db:create
```

Create a Vegetable model (with name and weight fields), and vegetables controller

```bash
rails g model Vegetable name:string weight:decimal 
rails g controller vegetables 
```

Migrate the newly created model

```bash
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

def r_script(script)
r = RinRuby.new # establishing a new RinRuby connection
r.eval(script) # run script

return r.pull 'final' # 'Pull' the results
r.quit
r = RinRuby.new(false) # Close the connection

end
```

And make a simple R script

```ruby
script = <<-DOC
install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)
some_numbers <- 20 %>% { 3 * . } %>% { . * c(1,2,3) }
some_numbers %>% return(.)
DOC
```

Now run it with

```ruby
r_script(script)
```

Or run it and return the results as a ruby object as so 

```ruby
def run_r_script(script)

    r =  RinRuby.new # establishes a new RinRuby connection
    r.eval(script)
    return r.pull 'some_numbers' # Be sure to return the object assigned in R script
    r.quit
    r = RinRuby.new(false)

end

# Run the method above and assign the output
output = run_r_script(script)
output

```










