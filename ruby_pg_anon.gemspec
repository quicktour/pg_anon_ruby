Gem::Specification.new do |s|
  s.name        = 'ruby_pg_anon'
  s.version     = '0.0.0'
  s.date        = '2020-10-26'
  s.summary     = "ruby postgresql anonymizer"
  s.description = "Bridge for working with postgres anonymizer"
  s.authors     = ["Kuras Viktor"]
  s.email       = 'kurasviktor@gmail.com'
  s.files       = `git ls-files -c -o --exclude-standard -z -- lib/* bin/* ruby_pg_anon.gemspec`.split("\x0")
  s.homepage    = 'https://rubygems.org/gems/ruby_pg_anon'
  s.license     = 'MIT'
end