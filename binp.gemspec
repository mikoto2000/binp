require_relative 'lib/binp/version'

Gem::Specification.new do |spec|
  spec.name          = "binp"
  spec.version       = Binp::VERSION
  spec.authors       = ["mikoto2000"]
  spec.email         = ["mikoto2000@gmail.com"]

  spec.summary       = %q{binary file parser.}
  spec.description   = %q{simple binary file parser.}
  spec.homepage      = "https://github.com/mikoto2000/binp"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://rubygems.org/gems/binp"
  spec.metadata["changelog_uri"] = "https://github.com/mikoto2000/binp/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'simplecov'
end
