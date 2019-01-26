


desc "This task is called by the Heroku scheduler add-on"
task :example_usage => :environment do



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
install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

new_vegetables <- c("Garlic", "Ginger", "Bok Choy")

new_vegetables %>% return(.)

DOC



new_vegetables = run_r_script(script, "new_vegetables")
new_vegetables



script = <<-DOC
# Note: not necessary to run install.packages every time, just the first
# install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)

weights <- 20 %>% { 3 * . } %>% { . * c(1,2,3) }

weights %>% return(.)

DOC


weights = run_r_script(script, "weights")
weights



for i in 0..(new_vegetables.length-1) do 
	@vegetable = Vegetable.new(name: new_vegetables[i], weight: weights[i].to_d)
	@vegetable.save
end





end # Ends first task, add more below if desired


