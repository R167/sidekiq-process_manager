# frozen_string_literal: true

require_relative "lib/sidekiq/process_manager/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq-process_manager"
  spec.version       = Sidekiq::ProcessManager::VERSION
  spec.authors       = ["Brian Durand"]
  spec.email         = ["bbdurand@gmail.com"]

  spec.summary       = "Process manager for forking and monitoring multiple sidekiq processes."
  spec.homepage      = "https://github.com/bdurand/sidekiq-process_manager"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_files = %w(
    .gitignore
    .travis.yml
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    gemfiles/
    spec/
  )
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject{ |f| ignore_files.any?{ |path| f.start_with?(path) } }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2.2'

  spec.add_dependency "sidekiq", ">= 3.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "appraisal"
end
