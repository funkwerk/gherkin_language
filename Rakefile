require 'rake/testtask'

task default: :build

desc 'Builds the Gem.'
task build: :test do
  sh 'gem build gherkin_language.gemspec'
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task test: :rubocop
task test: :cucumber

desc 'Publishes the Gem'
task :push do
  sh 'gem push gherkin_language-0.0.2.gem'
end

desc 'Checks ruby style'
task :rubocop do
  sh 'rubocop'
end

task :cucumber do
  sh 'cucumber'
end
