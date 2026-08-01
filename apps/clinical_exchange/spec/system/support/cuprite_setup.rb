# frozen_string_literal: true

require "capybara/cuprite"

# Run with HEADLESS=false to watch the browser, INSPECTOR=true to attach
# devtools and pause on `page.driver.debug`.
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1200, 800 ],
    browser_options: { "no-sandbox": nil },
    headless: ENV.fetch("HEADLESS", "true") != "false",
    inspector: ENV["INSPECTOR"] == "true",
    js_errors: false
  )
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
