require 'rails_helper'
require 'rinruby'





RSpec.describe Lamborghini, type: :model do

  context 'column tests - data types' do


    let(:r) {RinRuby.new}



    it 'ensures transport_column converts ActiveSupport::TimeZone (ruby) to POSIXct (R)' do


      some_dates = ["2019-02-23", "1981-01-04", "2020-12-31"]
      dates = some_dates.map{ |e| ActiveSupport::TimeZone['UTC'].parse(e) }  
      r.eval Transport.transport_column("dates", dates)

      r.eval "result <- class(dates)[1]"
      result = r.pull "result"
     
      expect(result).to eq("POSIXct")


    end



    it 'ensures transport_column converts Integer (ruby) to integer (R)' do


      some_integers = [1,2,3,4]
      r.eval Transport.transport_column("some_integers", some_integers)

      r.eval "result <- class(some_integers)[1]"
      result = r.pull "result"
     
      expect(result).to eq("integer")


    end


    it 'ensures transport_column converts String (ruby) to character (R)' do


      some_strings = ["hello", "world", "123"]
      r.eval Transport.transport_column("some_strings", some_strings)

      r.eval "result <- class(some_strings)[1]"
      result = r.pull "result"
      
      expect(result).to eq("character")


    end



    it 'ensures transport_column converts BigDecimal (ruby) to numeric (R)' do


      some_BigDecimals = [0.123, 1.456, 4839.009384].map { |e| e.to_d }
      r.eval Transport.transport_column("some_BigDecimals", some_BigDecimals)

      r.eval "result <- class(some_BigDecimals)[1]"
      result = r.pull "result"
     
      expect(result).to eq("numeric")


    end




    it 'ensures transport_column converts Float (ruby) to numeric (R)' do


      some_floats = [0.123, 1.456, 4839.009384]
      r.eval Transport.transport_column("some_floats", some_floats)

      r.eval "result <- class(some_floats)[1]"
      result = r.pull "result"
      
      expect(result).to eq("numeric")


    end



    it 'ensures transport_column converts TrueClass and FalseClass (ruby) to logical (R)' do


      some_TrueClass_and_FlaseClass = [true, false, false, true]
      r.eval Transport.transport_column("some_TrueClass_and_FlaseClass", some_TrueClass_and_FlaseClass)

      r.eval "result <- class(some_TrueClass_and_FlaseClass)[1]"
      result = r.pull "result"
     
      expect(result).to eq("logical")


    end



    it 'ensures transport_column can handle an entire column of nil values' do


      all_nils = [nil, nil, nil, nil]
      r.eval Transport.transport_column("all_nils", all_nils)

      r.eval "result <- ifelse(is.na(all_nils[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
     
      expect(result).to eq("Value is NA")

    end




  end







  context 'column tests - handling occasional nil values in columns' do



    let(:r) {RinRuby.new}


    it 'ensures transport_column handles nil in ActiveSupport::TimeZone' do


      some_dates = [nil, "1981-01-04", "2020-12-31"]
      dates = some_dates.map{ |e| e.nil? ? nil : ActiveSupport::TimeZone['UTC'].parse(e) }  
      r.eval Transport.transport_column("dates", dates)

      r.eval "result <- ifelse(is.na(dates[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
     
      expect(result).to eq("Value is NA")


    end



    it 'ensures transport_column handles nil in Integer' do


      some_integers = [nil,2,3,4]
      r.eval Transport.transport_column("some_integers", some_integers)

      r.eval "result <- ifelse(is.na(some_integers[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
     
      expect(result).to eq("Value is NA")


    end


    it 'ensures transport_column handles nil in String' do


      some_strings = [nil, "world", "123"]
      r.eval Transport.transport_column("some_strings", some_strings)

      r.eval "result <- ifelse(is.na(some_strings[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
      
      expect(result).to eq("Value is NA")


    end



    it 'ensures transport_column handles nil in BigDecimal' do


      some_BigDecimals = [nil, 1.456, 4839.009384].map { |e| e.nil? ? nil : e.to_d }
      r.eval Transport.transport_column("some_BigDecimals", some_BigDecimals)

      r.eval "result <- ifelse(is.na(some_BigDecimals[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
     
      expect(result).to eq("Value is NA")


    end




    it 'ensures transport_column handles nil in Float' do


      some_floats = [nil, 1.456, 4839.009384]
      r.eval Transport.transport_column("some_floats", some_floats)

      r.eval "result <- ifelse(is.na(some_floats[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
      
      expect(result).to eq("Value is NA")


    end



    it 'ensures transport_column handles nil in TrueClass and FalseClass' do


      some_TrueClass_and_FlaseClass = [nil, false, true, nil]
      r.eval Transport.transport_column("some_TrueClass_and_FlaseClass", some_TrueClass_and_FlaseClass)

      r.eval "result <- ifelse(is.na(some_TrueClass_and_FlaseClass[1]), 'Value is NA', 'Not NA')"
      result = r.pull "result"
     
      expect(result).to eq("Value is NA")


    end



  end







  context 'dataframe tests' do


    let(:r) {RinRuby.new}

    it 'ensures transport_dataframe converts moves an n x m dataframe into R' do
      
      # Insert some data into test db
      @lamborghini = Lamborghini.new(name: "Lamborghini Veneno Roadster", price: 5000000, year: 2014)
      @lamborghini.save

      @lamborghini = Lamborghini.new(name: "Lamborghini Veneno", price: 4500000, year: 2013)
      @lamborghini.save

      @lamborghini = Lamborghini.new(name: "Lamborghini Sesto Element Concept", price: 3000000, year: 2010)
      @lamborghini.save

      
      r.eval Transport.transport_dataframe("some_dataframe", "Lamborghini", r)

      r.eval "result <- dim(some_dataframe)"
      result = r.pull "result"
      
      number_of_columns = eval("Lamborghini").column_names.length
      number_of_rows = eval("Lamborghini").count


      expect(result[0]).to eq(number_of_rows)
      expect(result[1]).to eq(number_of_columns)

      
    end



  end






















end
