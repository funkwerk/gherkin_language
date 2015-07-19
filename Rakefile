require 'rake/testtask'

task default: :build

desc 'Builds the Gem.'
task build: :test do
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
task :push do
  sh 'gem push gherkin_language-0.0.6.gem'
end

desc 'Checks ruby style'
task :rubocop do
  sh 'rubocop'
end

task :cucumber do
  sh 'cucumber'
end

task :lint do
  sh 'gherkin_lint --disable UnknownVariable features/*.feature'
end

task :format do
  sh 'gherkin_format features/*.feature'
end
