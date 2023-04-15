# dokuwiki.gemspec
Gem::Specification.new do |s|
  s.name = 'dokuwiki'
  s.version = '1.2'
  s.date = '2023-04-13'
  s.summary = 'access DokuWiki server'
  s.description = 'The DokuWiki library is used for automating interaction with a DokuWiki server.'
  s.authors = ['Dirk Meyer']
  s.homepage = 'https://rubygems.org/gems/dokuwiki'
  s.licenses = ['MIT']
  s.files = ['lib/dokuwiki.rb', '.rubocop.yml']
  s.files += Dir['[A-Z]*']
  s.add_runtime_dependency 'http-cookie', ['~> 1.0', '>= 1.0.3']
  s.add_runtime_dependency 'mechanize', ['~> 2.7', '>= 2.7.6']
end
