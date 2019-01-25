


namespace :example do

  desc "Tire reindex profiles"

  task :example_usage => :environment do

# The lines above (and the final two 'ends') are the requirements for this to be a rake task
# E.g. see here: https://stackoverflow.com/questions/12903069/simple-rails-rake-task-refuse-to-run-with-error-dont-know-how-to-build-task








# Based on the tutorial here:
# https://www.standardco.de/using-r-in-rails

require 'rinruby'



def r_script(script)
r = RinRuby.new # establishing a new RinRuby connection
r.eval(script) # run script
end



script = <<-DOC
install.packages('dplyr', dependencies = TRUE, repos='https://cran.csiro.au/')
library(dplyr)
2 %>% { 3 * . } %>% { . * c(1,2,3,4) }
DOC








end

end


