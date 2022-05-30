Gem::Specification.new do |s|
  s.name        = "rubycraft"
  s.version     = "1.2"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Josh Hertlein"]
  s.email       = ["jmhertlein@gmail.com"]
  s.homepage    = "https://github.com/jmhertlein/RubyCraft"
  s.summary     = "A tool for managing minecraft servers."
  s.description = "A tool for managing minecraft server on UNIX systems."

  s.required_rubygems_version = ">= 2.5.1"

  s.add_dependency "colorize", "~> 0.8.1"

  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'

  s.executables = ["rc"]
end
