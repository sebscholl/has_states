# frozen_string_literal: true

RSpec.describe HasStates do
  it "has a version number" do
    expect(HasStates::VERSION).not_to be_nil
  end

  it "has a configuration" do
    expect(described_class.configuration).to be_a(HasStates::Configuration)
  end

  it "can be configured" do
    described_class.configure do |config|
      config.state_types = ["kyc"]
      config.statuses = %w[pending completed]
    end

    expect(described_class.configuration.state_types).to eq(["kyc"])
    expect(described_class.configuration.statuses).to eq(%w[pending completed])
  end
end
