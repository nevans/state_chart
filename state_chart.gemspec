require_relative 'lib/state_chart/version'

Gem::Specification.new do |spec|
  spec.name          = "state_chart"
  spec.version       = StateChart::VERSION
  spec.authors       = ["nicholas a. evans"]
  spec.email         = ["nicholas.evans@gmail.com"]

  spec.summary       = %q{State machines with heirarchy, parallelism, history, and more.}
  spec.description   = <<~DESC
    A state machine is a finite set of states that can transition to each other
    deterministically due to events.  A statechart is an extension of state
    machines, which can have:
    * hierarchical (nested) states,
    * orthogonal (parallel) states
    * history states,
    * and more

    The StateChart gem is inspired by SCXML and xstate.js, and aims to
    (eventually) be mostly compatible with both.
  DESC
  spec.homepage      = "https://github.com/nick_evans/state_chart"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/nick_evans/state_chart"
  spec.metadata["changelog_uri"] = "https://github.com/nevans/state_chart/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "docile", "~> 1.3.2"

end
