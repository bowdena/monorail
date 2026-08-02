# Rate limits count through Rails.cache, which outlives an example. A
# full run makes more searches a minute than the cap allows, so without
# this the examples that happen to run last are throttled and fail.
RSpec.configure do |config|
  config.before { Rails.cache.clear }
end
