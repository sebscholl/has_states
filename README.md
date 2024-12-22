# HasStates

HasStates is a flexible state management gem for Ruby on Rails that allows you to add multiple state machines to your models. It provides a simple way to track state transitions, add metadata, and execute callbacks.

## Features

- Multiple state machines per model
- JSON metadata storage for each state
- Configurable callbacks with conditions
- Limited execution callbacks
- Automatic scope generation
- Simple state transition tracking

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has_states'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install has_states
```

## Setup

Run the installation generator:
```bash
$ rails has_states:install
```

This will create a migration for the states table. Run the migration:
```bash
$ rails db:migrate
```

## Basic Usage

First, configure your states in an initializer:

```ruby
# config/initializers/has_states.rb
HasStates.configure do |config|
  config.models = ['User', 'Company']
  config.state_types = ['kyc', 'onboarding']
  config.statuses = ['pending', 'completed', 'failed']
end
```

Now you can use states in your models:

```ruby
class User < ApplicationRecord
  # HasStates is automatically included based on configuration. 
  # If you want to include it manually, use:
  # include HasStates::Stateable
end

user = User.create!(name: 'John')

# Add a new state
state = user.add_state('kyc', status: 'pending', metadata: { 
  documents: ['passport', 'utility_bill']
})

# Check current state
user.current_state('kyc') # => state object
state.pending? # => true

# Update state
state.update!(status: 'completed')
```

## Callbacks

You can register callbacks that execute when states change:

```ruby
HasStates.configure do |config|
  # Basic callback
  config.on(:kyc, to: 'completed') do |state|
    UserMailer.kyc_completed(state.stateable).deliver_later
  end

  # Callback with custom ID
  config.on(:kyc, id: :notify_admin, to: 'failed') do |state|
    AdminNotifier.kyc_failed(state)
  end

  # Limited execution callback (runs only twice)
  config.on(:onboarding, to: 'completed', times: 2) do |state|
    WelcomeMailer.send_welcome(state.stateable)
  end
end
```

Remove callbacks:
```ruby
# Remove by ID
HasStates.configuration.off(:notify_admin)

# Remove by callback object
callback = HasStates.configuration.on(:kyc) { |state| puts "Called" }
HasStates.configuration.off(callback)
```

## Metadata

Each state can store arbitrary metadata as JSON:

```ruby
state = user.add_state('kyc', metadata: {
  documents: {
    passport: { status: 'verified', verified_at: Time.current },
    utility_bill: { status: 'pending' }
  },
  notes: ['Document expired', 'Needs review'],
  reviewer_id: 123
})

state.metadata['documents']['passport']['status'] # => "verified"
```

## Scopes

HasStates automatically generates scopes for your state types:

```ruby
HasStates::State.kyc # => Returns all KYC states
HasStates::State.onboarding # => Returns all onboarding states
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/has_states.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

