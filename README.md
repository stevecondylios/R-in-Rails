# NOTES


Create a rails app 

```bash
rails new R-in-Rails --database=postgresql
```

Before making a database, add `gem 'rinruby'` to the gemfile and `bundle install`


Create a Vegetable model (with name and weight fields), and vegetables controller

```bash
rails g model Vegetable name:string weight:decimal 
rails g controller vegetable 
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
end
```

And make a simple R script

```ruby
script = <<-DOC
install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)
2 %>% { 3 * . } %>% { . * c(1,2,3,4) } %>% print(.)
DOC
```

Now run it with

```ruby
r_script(script)
```































