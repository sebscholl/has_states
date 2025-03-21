# HasStates

HasStates is a flexible state management gem for Ruby on Rails that allows you to add multiple state machines to your models. It provides a simple way to track state transitions, add metadata, and execute callbacks.

## Features

- Multiple state types per model
- Model-specific state configurations
- JSON metadata storage for each state
- Configurable callbacks with conditions
- Limited execution callbacks
- Automatic scope generation
- Simple state transition tracking

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stateful_models'
```

Then execute:
```bash
$ bundle install
```

Generate the required migration and initializer:
```bash
$ rails generate has_states:install
```

Finally, run the migration:
```bash
$ rails db:migrate
```

## Configuration

Configure your models and their state types in `config/initializers/has_states.rb`:

```ruby
HasStates.configure do |config|
  # Configure states on any model
  config.configure_model User do |model|
    # Define state type and its allowed statuses
    model.state_type :kyc do |type|
      type.statuses = [
        'pending',              # Initial state
        'documents_required',   # Waiting for documents
        'under_review',        # Documents being reviewed
        'approved',            # KYC completed successfully
        'rejected'             # KYC failed
      ]
    end

    # Define multiple state types per model with different statuses
    model.state_type :onboarding do |type|
      type.statuses = [
        'pending',          # Just started
        'email_verified',   # Email verification complete
        'completed'         # Onboarding finished
      ]
    end
  end

  # Configure multiple models
  config.configure_model Company do |model|
    model.state_type :verification do |type|
      type.statuses = ['pending', 'verified', 'rejected']
    end
  end
end
```

## Usage

### Basic State Management

```ruby
user = User.create!(name: 'John')
# Add a new state
state = user.add_state('kyc', status: 'pending', metadata: {
  documents: ['passport', 'utility_bill'],
  notes: 'Awaiting document submission'
})

# Check current state
current_kyc = user.current_state('kyc')

# Predicate methods are generated for every status.
current_kyc.pending?  # => true
current_kyc.approved? # => false

# Update state
current_kyc.update!(status: 'under_review')

# Check state for record 
user.kyc_pending? # => true
user.kyc_completed? # => false

# See all states for record
user.states # => [#<HasStates::State...>]
```

### Working with Metadata

Each state can store arbitrary metadata as JSON:

```ruby
# Store complex metadata
state = user.add_state('kyc', metadata: {
  documents: {
    passport: { 
      status: 'verified',
      verified_at: Time.current,
      verified_by: 'admin@example.com'
    },
    utility_bill: { 
      status: 'rejected',
      reason: 'Document expired'
    }
  },
  risk_score: 85,
  notes: ['Requires additional verification', 'High-risk jurisdiction']
})

# Access metadata
state.metadata['documents']['passport']['status'] # => "verified"
state.metadata['risk_score'] # => 85
```

## State Limits

You can optionally limit the number of states a record can have for a specific state type:

```ruby
HasStates.configure do |config|
  config.configure_model User do |model|
    model.state_type :kyc do |type|
      type.statuses = %w[pending completed]
      type.limit = 1  # Limit to only one KYC state per user
    end
  end
end
```

When set, the limit is checked when a new state is added. If the limit is exceeded, an ActiveRecord::RecordInvalid error is raised.

### Callbacks

Register callbacks that execute when states change:

```ruby
HasStates.configure do |config|
  # Basic callback
  config.on(:kyc, to: 'completed') do |state|
    UserMailer.kyc_completed(state.stateable).deliver_later
  end

  # Callback with custom ID for easy removal
  config.on(:kyc, id: :notify_admin, to: 'rejected') do |state|
    AdminNotifier.kyc_rejected(state)
  end

  # Callback that runs only once
  config.on(:onboarding, to: 'completed', times: 1) do |state|
    WelcomeMailer.send_welcome(state.stateable)
  end

  # Callback with from/to conditions
  config.on(:kyc, from: 'pending', to: 'under_review') do |state|
    NotificationService.notify_review_started(state)
  end
end

# Remove callbacks
HasStates.configuration.off(:notify_admin)  # Remove by ID
HasStates.configuration.off(callback)       # Remove by callback object
```

### Scopes

HasStates automatically generates scopes for your state types:

```ruby
HasStates::State.kyc              # All KYC states
HasStates::State.onboarding      # All onboarding states
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/has_states.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

