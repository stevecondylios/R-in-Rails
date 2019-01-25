


namespace :example do

  desc "Use R to generate some data and save it to rails database"

  task :example_usage => :environment do

# The lines above (and the final two 'ends') are the requirements for this to be a rake task
# E.g. see here: https://stackoverflow.com/questions/12903069/simple-rails-rake-task-refuse-to-run-with-error-dont-know-how-to-build-task








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













end

end


