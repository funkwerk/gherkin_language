Gem::Specification.new do |s|
  s.name        = 'gherkin_language'
  s.version     = '0.3.0'
  s.date        = '2016-07-13'
  s.summary     = 'Gherkin Language'
  s.description = 'Check language of Gherkin Files'
  s.authors     = ['Stefan Rohe']
  s.homepage    = 'http://github.com/funkwerk/gherkin_language/'
  s.files       = `git ls-files`.split("\n")
  s.executables = s.files.grep(%r{^bin/}) { |file| File.basename(file) }
  s.add_runtime_dependency 'gherkin', ['= 2.12.2']
  s.add_runtime_dependency 'term-ansicolor', ['>= 1.3.2']
  s.add_runtime_dependency 'syllables', ['>= 0.1.4']
  s.add_development_dependency 'aruba', ['>= 0.6.2']
end
