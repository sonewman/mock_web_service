require "bundler/gem_tasks"
require 'rspec/core/rake_task'

namespace :unit do

desc "MockWebService"
  RSpec::Core::RakeTask.new(:run) do |t|
    t.rspec_opts = "-f d --require spec_helper"
  end
end
