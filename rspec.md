

# Rspec steps
# From: https://www.youtube.com/watch?v=71eKcNxwxVY

```
gem 'rspec-rails'
bundle

rails g rspec:install
rails g rspec:model lamborghini
```

Add some tests in models/lamborghini_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Lamborghini, type: :model do

  context 'validation tests' do

    it 'ensures first name present' do
      user = User.new(last_name: 'Last', email: 'sample@example.com').save
      expect(user).to eq(flase) # we expect false sinc we're not providing a first name
    end

    it 'ensures last name present' do
      user = User.new(first_name: 'Last', email: 'sample@example.com').save
      expect(user).to eq(flase) # we expect false sinc we're not providing a first name
    end

    it 'ensures email present' do
      user = User.new(first_name: 'dave', last_name: 'smith').save
      expect(user).to eq(flase) # we expect false sinc we're not providing a first name
    end

    it 'should save successfully' do
      user = User.new(first_name: 'Dave', last_name: 'Last', email: 'sample@example.com').save
      expect(user).to eq(true) # we expect false sinc we're not providing a first name
    end

  end


  context 'scope tests' do

  end

end
```


Add to .rspec to ensure full output in console

```
--require spec_helper
--format documentation
```

Now run the tests with

```
rspec
```

They'll all fail. Now get to work making them pass!







































