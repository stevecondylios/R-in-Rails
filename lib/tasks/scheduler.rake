


desc "This task creates uses R to create data and rails to insert 3 rows into the database - this task can be called manually but can also be scheduled using heroku scheduler"
task :lambo => :environment do



puts 'Running scheduled task'

# Based on the tutorial here:
# https://www.standardco.de/using-r-in-rails



require 'rinruby'

def run_r_script(script, object_to_return)

    r =  RinRuby.new # establishes a new RinRuby connection
    r.eval(script)
    return r.pull object_to_return.to_s # Be sure to return the object assigned in R script
    r.quit
    r = RinRuby.new(false)

end




script = <<-DOC
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

new_lamborghinis <- c("Lamborghini Cala Concept", "Lamborghini Egoista Concept", "Lamborghini Miura Concept")

new_lamborghinis %>% return(.)

DOC


new_lamborghinis = run_r_script(script, "new_lamborghinis")
new_lamborghinis



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


prices = run_r_script(script, "prices")
prices



script = <<-DOC
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

years <- c(1995, 2013, 2006) %>% as.integer

years %>% return(.)

DOC





years = run_r_script(script, "years")
years



for i in 0..(new_lamborghinis.length-1) do 
	@lamborghini = Lamborghini.new(name: new_lamborghinis[i], price: prices[i].to_d, year: years[i])
	@lamborghini.save
end





end # Ends first task, add more below if desired


