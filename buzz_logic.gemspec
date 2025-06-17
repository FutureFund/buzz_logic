require_relative "lib/buzz_logic/version"

Gem::Specification.new do |spec|
  spec.name    = "buzz_logic"
  spec.version = BuzzLogic::VERSION
  spec.authors = [ "Darian Shimy" ]
  spec.email   = [ "dshimy@futurefund.com" ]

  spec.summary     = "A simple, powerful, and secure rules engine for busy bees."
  spec.description = "BuzzLogic, created by FutureFund, allows dynamic rule evaluation against application objects for platforms like our K-12 fundraising site. It avoids the risks of arbitrary code execution by using a custom, secure parser."
  spec.homepage    = "https://github.com/futurefund/buzz_logic"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "https://github.com/FutureFund/buzz_logic/CHANGELOG.md"
  spec.metadata["github_repo"]     = "ssh://github.com/FutureFund/buzz_logic"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]
end
