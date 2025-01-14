 # frozen_string_literal: true

# Configure after the application is initialized
Rails.application.config.after_initialize do
  HasStates.configure do |config|
    # Configure your models and their state types below
    #
    # Example configuration:
    #
    config.configure_model User do |model|
      # KYC state type with its allowed statuses
      model.state_type :kyc do |type|
        type.statuses = [
          'pending',              # Initial state
          'documents_required',   # Waiting for user documents
          'under_review',        # Documents being reviewed
          'approved',            # KYC process completed successfully
          'rejected'             # KYC process failed
        ]
      end
    
      # Onboarding state type with different statuses
      model.state_type :onboarding do |type|
        type.statuses = [
          'pending',          # Just started
          'email_verified',   # Email verification complete
          'profile_complete', # User filled all required fields
          'completed'         # Onboarding finished
        ]
      end
    end
    #
    # config.configure_model Company do |model|
    #   model.state_type :verification do |type|
    #     type.statuses = [
    #       'pending',
    #       'documents_submitted',
    #       'under_review',
    #       'verified',
    #       'rejected'
    #     ]
    #   end
    # end
  end
end