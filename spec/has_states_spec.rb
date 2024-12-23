# frozen_string_literal: true

RSpec.describe HasStates do
  it 'has a version number' do
    expect(HasStates::VERSION).not_to be_nil
  end

  it 'has a configuration' do
    expect(described_class.configuration).to be_a(HasStates::Configuration)
  end

  describe 'configuration' do
    before do
      described_class.configure do |config|
        # User configuration
        config.configure_model User do |model|
          model.state_type :kyc do |type|
            type.statuses = %w[pending completed]
          end

          model.state_type :onboarding do |type|
            type.statuses = %w[started finished]
          end
        end

        # Company configuration
        config.configure_model Company do |model|
          model.state_type :procurement do |type|
            type.statuses = %w[in_progress completed failed]
          end
        end
      end
    end

    it 'configures the state types for User' do
      expect(described_class.configuration.state_types_for(User).keys).to eq(%w[kyc onboarding])
    end

    it 'configures the statuses for User' do
      expect(described_class.configuration.statuses_for(User, 'kyc')).to eq(%w[pending completed])
      expect(described_class.configuration.statuses_for(User, 'onboarding')).to eq(%w[started finished])
    end

    it 'configures the state types for Company' do
      expect(described_class.configuration.state_types_for(Company).keys).to eq(['procurement'])
    end

    it 'configures the statuses for Company' do
      expect(described_class.configuration.statuses_for(Company, 'procurement')).to eq(%w[in_progress completed failed])
    end
  end
end
