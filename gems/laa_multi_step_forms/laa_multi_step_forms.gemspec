require_relative 'lib/laa_multi_step_forms/version'

Gem::Specification.new do |spec|
  spec.name        = 'laa_multi_step_forms'
  spec.version     = LaaMultiStepForms::VERSION
  spec.authors     = ['David Henry']
  spec.email       = ['david.henry@digital.justice.gov.uk']
  # spec.homepage    = "TODO"
  spec.summary     = 'Multipart forms for LAA'
  spec.description = 'Base implementation of multipart forms for LAA'
  spec.required_ruby_version = '>= 3.2'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata['allowed_push_host'] = ''

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 7.0.4.3'
  spec.add_development_dependency 'rubocop', '~> 1.49.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
