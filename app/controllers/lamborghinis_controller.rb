class LamborghinisController < ApplicationController

def index
@rows = Lamborghini.count
end


end
