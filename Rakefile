require 'rake/testtask'

task default: :build

desc 'Builds the Gem.'
# TODO: cause it fails on travis-ci task build: :test
task :build  do
  sh 'gem build gherkin_language.gemspec'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task test: :format
task test: :lint
task test: :rubocop
task test: :cucumber

desc 'Publishes the Gem'
task push: :build do
  sh 'gem push gherkin_language-0.9.0.gem'
end

desc 'Checks ruby style'
task :rubocop do
  sh 'rubocop'
end

task :cucumber do
  options = %w()
  options.push '--tags ~@slow' unless ENV['slow']
  sh "cucumber #{options * ' '}"
end

task :lint do
  sh 'gherkin_lint --disable UnknownVariable features/*.feature'
end

task :format do
  sh 'gherkin_format --replace features/*.feature'
end
