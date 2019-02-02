module Transport
  

  def self.determine_class(array)
    data_types = array.group_by(&:class).sort_by{|k, v| v.length}
    if data_types.length == 1 && data_types[0][0] == NilClass
      # This handles for the rare case of an entire column of nil values
      most_prevalent_data_type = NilClass 
    else
      # This says if NilClass happens to be the most common class, use the next most common class
      most_prevalent_data_type = data_types[0][0] == NilClass ? data_types[1][0] : data_types[0][0] 
    end
    return most_prevalent_data_type
  end




  def self.transport_column(r_var_name, array)

    most_prevalent_data_type = Transport.determine_class(array)

    if most_prevalent_data_type == String
      vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.to_s.gsub('"NA"', "NA_character_")[1..-2]
      content = 'c(' + vector_as_string + ')'
    elsif
      most_prevalent_data_type == Float || most_prevalent_data_type == BigDecimal
      vector_as_string = array.map { |e| e.nil? ? "NA" : e }
      content = 'c(' + vector_as_string.join(', ') + ')'
    elsif
      most_prevalent_data_type == Integer
      vector_as_string = array.map { |e| e.nil? ? "NA" : e }
      content = 'as.integer(c(' + vector_as_string.join(', ') + '))'
    elsif
      most_prevalent_data_type == ActiveSupport::TimeWithZone 
      vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.map { |e| e.to_s }.to_s.gsub('"NA"', "NA_character_")[1..-2]
      content = 'as.POSIXct(c(' + vector_as_string + '))'
    elsif
      most_prevalent_data_type == TrueClass || most_prevalent_data_type == FalseClass
      vector_as_string = array.map { |e| e.nil? ? "NA_character_" : e }.map { |e| e == "NA_character_" ? e : e.to_s.upcase }.to_s.gsub('"', "")[1..-2]
      content = 'as.logical(c(' + vector_as_string + '))'
    elsif 
      most_prevalent_data_type == NilClass
      vector_as_string = (["NA_character_"] * array.length).to_s.gsub('"', "")[1..-2]
      content = 'as.logical(c(' + vector_as_string + '))'
    else
      # Any data types other than those above will be moved as ruby strings to R character
      vector_as_string = array.map{ |e| e.nil? ? "NA" : e }.map { |e| e.to_s }.to_s.gsub('"NA"', "NA_character_")[1..-2]
      content = 'c(' + vector_as_string + ')'
    end 

    output = r_var_name.to_s + " <- " + content
    # output = output + "; print(" + r_var_name.to_s + ")"
    return output
  end




  def self.transport_dataframe(r_dataframe_name, model, connection)

    r = connection

    array_of_arrays = eval(model).column_names.map { |column| eval(model).all.order(:id).map(&column.to_sym) }
    # Note: .order(:id) means that if attributes have been edited and the ids are out of order, it will return data in correct orders

    column_names = eval(model).column_names

    # Transport each column to R interpreter
    array_of_arrays.each_with_index do |column, index|
      puts index
      r.eval Transport.transport_column(column_names[index], column) 
    end

    # Now create an R dataframe from the columns 
    output = r_dataframe_name.to_s + " <- data.frame(" + column_names.join(', ') + ", stringsAsFactors=FALSE); print(" + r_dataframe_name + ")"

    return output

  end



end















