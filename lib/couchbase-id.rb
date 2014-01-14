require 'radix'
if RUBY_PLATFORM == 'java'
    require 'couchbase-jruby-model'
else
    require 'couchbase-model'
end
require 'couchbase-id/generator'


module CouchbaseId
end
