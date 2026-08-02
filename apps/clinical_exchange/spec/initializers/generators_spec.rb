require "rails_helper"

RSpec.describe "Generators" do
  it "generates new tables with uuid primary keys" do
    generators = Rails.application.config.generators.options

    expect(generators[:active_record][:primary_key_type]).to eq(:uuid)
  end
end
