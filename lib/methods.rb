

# gem 'rootapp-rinruby'
# rails g model Lamborghini name:string price:decimal year:integer



@lamborghini = Lamborghini.new(name: "Lamborghini Veneno Roadster", price: 5000000, year: 2014)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Veneno", price: 4500000, year: 2013)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Sesto Element Concept", price: 3000000, year: 2010)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Cala Concept ", price: 3000000, year: 1995)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Egoista Concept", price: 3000000, year: 2013)
@lamborghini.save

@lamborghini = Lamborghini.new(name: "Lamborghini Miura Concept", price: 3000000, year: 2006)
@lamborghini.save













require 'rinruby'

r = RinRuby.new







#----- Method for getting a column/vector into R -----#

def transport_column(r_var_name, array) 

  sample = array.length < 100 ? array.length : 100 
  most_prevalent_data_type_in_first_100_elements = array[0..sample].group_by(&:class).max_by{|k, v| v.length}.first

  if most_prevalent_data_type_in_first_100_elements == String
    array_2 = array.map{ |e| e.nil? ? "NA" : e }.to_s.gsub('"NA"', "NA_character_")[1..-2]
    content = 'c(' + array_2 + ')'
  end

  if most_prevalent_data_type_in_first_100_elements == Integer
    array_2 = array.map { |e| e ? e : "NA" }
    content = 'c(' + array_2.join(', ') + ')'
  end

  if most_prevalent_data_type_in_first_100_elements == Float 
    array_2 = array.map { |e| e ? e : "NA" }
    content = 'c(' + array_2.join(', ') + ')'
  end

  if most_prevalent_data_type_in_first_100_elements == ActiveSupport::TimeWithZone 
    array_2 = array.map{ |e| e.nil? ? "NA" : e }.map { |e| e.to_s }.to_s.gsub('"NA"', "NA_character_")[1..-2]
    content = 'as.POSIXct(c(' + array_2 + '))'
  end

  if most_prevalent_data_type_in_first_100_elements == BigDecimal 
    array = array.map { |e| e.nil? ? "NA" : e }.to_s.gsub('"', "")[1..-2]
    content = 'c(' + array + ')'
  end 

  output = r_var_name.to_s + " <- " + content

  # Print, just to confirm

  output = output + "; print(" + r_var_name.to_s + ")"

  output

end



# Examples

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

dates = Lamborghini.pluck(:updated_at)
r.eval transport_column("dates", dates)






#----- Method for getting entire table / dataframe into R -----#



def transport_dataframe(r_dataframe_name, model, connection)

  r = connection

  array_of_arrays = eval(model).column_names.map { |column| eval(model).all.order(:id).map(&column.to_sym) }
  # Note: .order(:id) means that if attributes have been edited and the ids are out of order, it will return data in correct orders

  column_names = eval(model).column_names

  # Transport each column to R interpreter
  array_of_arrays.each_with_index do |column, index|
    puts index
    r.eval transport_column(column_names[index], column) 
  end

  # Now create an R dataframe from the columns 
  output = r_dataframe_name.to_s + " <- data.frame(" + column_names.join(', ') + ", stringsAsFactors=FALSE); print(" + r_dataframe_name + ")"

  output

end





# Example usage


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














