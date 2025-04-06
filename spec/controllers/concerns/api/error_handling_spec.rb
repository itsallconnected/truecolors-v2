# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ErrorHandling do
  before do
    stub_const('FakeService', Class.new)
  end

  controller(Api::BaseController) do
    def failure
      FakeService.new
    end
  end

  describe 'error handling' do
    before do
      routes.draw { get 'failure' => 'api/base#failure' }
    end

    {
      ActiveRecord::RecordInvalid => 422,
      ActiveRecord::RecordNotFound => 404,
      ActiveRecord::RecordNotUnique => 422,
      Date::Error => 422,
      HTTP::Error => 503,
      Truecolors::InvalidParameterError => 400,
      Truecolors::NotPermittedError => 403,
      Truecolors::RaceConditionError => 503,
      Truecolors::RateLimitExceededError => 429,
      Truecolors::UnexpectedResponseError => 503,
      Truecolors::ValidationError => 422,
      OpenSSL::SSL::SSLError => 503,
      Seahorse::Client::NetworkingError => 503,
      Stoplight::Error::RedLight => 503,
    }.each do |error, code|
      it "Handles error class of #{error}" do
        allow(FakeService)
          .to receive(:new)
          .and_raise(error)

        get :failure

        expect(response)
          .to have_http_status(code)
        expect(FakeService)
          .to have_received(:new)
      end
    end
  end
end
