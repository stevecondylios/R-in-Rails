require 'rails_helper'
require 'rinruby'

def transport_column(data_items)
  r = RinRuby.new
  r.eval Transport.transport_column("data_items", data_items)
  if data_items.include? nil
    r.eval "data.type <- ifelse(is.na(data_items[1]), 'Value is NA', 'Not NA')"
  else
    r.eval "data.type <- class(data_items)[1]"
  end
  data_type = r.pull "data.type"
  r.quit
  return data_type
end

RSpec.describe "transport methods" do

  context 'column tests - data types' do

    it 'ensures transport_column converts ActiveSupport::TimeZone (ruby) to POSIXct (R)' do
      some_dates = ["2019-02-23", "1981-01-04", "2020-12-31"]
      dates = some_dates.map { |e| ActiveSupport::TimeZone['UTC'].parse(e) }
      data_type = transport_column dates
      expect(data_type).to eq("POSIXct")
    end

    it 'ensures transport_column converts Integer (ruby) to integer (R)' do
      data_type = transport_column [1,2,3,4]
      expect(data_type).to eq("integer")
    end

    it 'ensures transport_column converts String (ruby) to character (R)' do
      data_type = transport_column ["hello", "world", "123"]
      expect(data_type).to eq("character")
    end

    it 'ensures transport_column converts BigDecimal (ruby) to numeric (R)' do
      some_BigDecimals = [0.123, 1.456, 4839.009384].map { |e| e.to_d }
      data_type = transport_column some_BigDecimals
      expect(data_type).to eq("numeric")
    end

    it 'ensures transport_column converts Float (ruby) to numeric (R)' do
      data_type = transport_column [0.123, 1.456, 4839.009384]
      expect(data_type).to eq("numeric")
    end

    it 'ensures transport_column converts TrueClass and FalseClass (ruby) to logical (R)' do
      data_type = transport_column [true, false, false, true]
      expect(data_type).to eq("logical")
    end

    it 'ensures transport_column can handle an entire column of nil values' do
      data_type = transport_column [nil, nil, nil, nil]
      expect(data_type).to eq("Value is NA")
    end

  end

  context 'column tests - handling occasional nil values in columns' do

    it 'ensures transport_column handles nil in ActiveSupport::TimeZone' do
      some_dates = ["1981-01-04", "2020-12-31"]
      dates = some_dates.map { |e| ActiveSupport::TimeZone['UTC'].parse(e) }
      data_type = transport_column dates.unshift(nil)
      expect(data_type).to eq("Value is NA")
    end

    it 'ensures transport_column handles nil in Integer' do
      data_type = transport_column [nil, 2, 3, 4]
      expect(data_type).to eq("Value is NA")
    end

    it 'ensures transport_column handles nil in String' do
      data_type = transport_column [nil, "world", "123"]
      expect(data_type).to eq("Value is NA")
    end

    it 'ensures transport_column handles nil in BigDecimal' do
      some_BigDecimals = [1.456, 4839.009384].map(&:to_d)
      data_type = transport_column some_BigDecimals.unshift(nil)
      expect(data_type).to eq("Value is NA")
    end

    it 'ensures transport_column handles nil in Float' do
      data_type = transport_column [nil, 1.456, 4839.009384]
      expect(data_type).to eq("Value is NA")
    end

    it 'ensures transport_column handles nil in TrueClass and FalseClass' do
      data_type = transport_column [nil, false, true, nil]
      expect(data_type).to eq("Value is NA")
    end

  end

  context 'dataframe tests' do

    let(:r) { RinRuby.new } 

    it 'ensures transport_dataframe converts moves an n x m dataframe into R', :focus do     
      # Insert some data into test db
      Lamborghini.create(name: "Lamborghini Veneno Roadster", price: 5000000, year: 2014)
      Lamborghini.create(name: "Lamborghini Veneno", price: 4500000, year: 2013)
      Lamborghini.create(name: "Lamborghini Sesto Element Concept", price: 3000000, year: 2010)      
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