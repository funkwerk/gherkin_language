require 'aruba/cucumber'

Before do
  @aruba_timeout_seconds = 1000  # external java process, give it some time
end
