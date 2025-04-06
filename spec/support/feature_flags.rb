# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:example, :feature) do |example|
    feature = example.metadata[:feature]
    allow(Truecolors::Feature).to receive(:"#{feature}_enabled?").and_return(true)
  end
end
