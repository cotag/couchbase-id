require File.expand_path("../lib/couchbase-id/version", __FILE__)

Gem::Specification.new do |gem|
    gem.name          = 'couchbase-id'
    gem.version       = CouchbaseId::VERSION
    gem.license       = 'MIT'
    gem.authors       = ['Stephen von Takach']
    gem.email         = ['steve@cotag.me']
    gem.homepage      = 'https://github.com/cotag/couchbase-id'
    gem.summary       = 'Couchbase ID generator with XDCR support'
    gem.description   = 'Overwrites the existing couchbase-model id implementation'

    gem.required_ruby_version = '>= 1.9.2'
    gem.require_paths = ['lib']

    gem.add_runtime_dependency     'radix' # This converts numbers to the unicode representation

    gem.add_development_dependency 'rspec', '>= 2.14'
    gem.add_development_dependency 'rake', '>= 10.1'
    gem.add_development_dependency 'yard'

    gem.files = Dir["{lib}/**/*"] + %w(Rakefile couchbase-id.gemspec README.md LICENSE)
    gem.test_files = Dir['spec/**/*']
    gem.extra_rdoc_files = ['README.md']
end
