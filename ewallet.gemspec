Gem::Specification.new do |s|
  s.name        = 'ewallet'
  s.version     = '0.0.1'
  s.date        = '2016-04-22'
  s.summary     = 'BCA e-Wallet'
  s.description = 'A gem to access e-Wallet API'
  s.authors     = %w(Khairul)
  s.email       = %w(kyu.helf@gmail.com)
  s.files       = `git ls-files`.split('\n')
  s.homepage    = "https://github.com/kahirul/ewallet"
  s.license     = 'MIT'

  s.add_runtime_dependency 'excon', '~> 0.20'
end
