# frozen_string_literal: true

require 'rails_helper'
require 'generators/meta_states/install/install_generator'

RSpec.describe MetaStates::InstallGenerator do
  let(:destination) { File.expand_path('../templates', __dir__) }

  before do
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination)
  end

  it 'creates migration and initializer files' do
    generator = described_class.new
    generator.destination_root = destination
    generator.install

    # Check migration exists
    migration = Dir[File.join(destination, 'db/migrate/*_create_meta_states_states.rb')].first
    expect(migration).to be_present

    # Check initializer exists
    initializer = File.join(destination, 'config/initializers/meta_states.rb')
    expect(File.exist?(initializer)).to be true
  end
end
