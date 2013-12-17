#
# This disables the built in generator, faster then running validations twice
#  Forces models to include an ID generator
#
module Couchbase
    class Model
        class UUID
            def initialize(*args)
                
            end
            
            def next(*args)
                nil
            end
        end
    end
end

#
# This is our id generator, runs in the before save call back
#
module CouchbaseId
    
    # NOTE:: incr, decr, append, prepend == atomic
    module Generator
        

        # Basic compression using UTF (more efficient for ID's stored as strings)
        B65 = Radix::Base.new(Radix::BASE::B62 + ['-', '_', '~'])
        B10 = Radix::Base.new(10)

        # The cluster id this node belongs to (avoids XDCR clashes)
        CLUSTER_ID ||= ENV['COUCHBASE_CLUSTER'] || 1     # Cluster ID number

        # instance method
        def generate_id
            if self.id.nil?                
                #
                # Generate the id (incrementing values as required)
                #
                overflow = self.class.__overflow__ ||= self.class.bucket.get("#{self.class.design_document}:#{CLUSTER_ID}:overflow", :quiet => true) # Don't error if not there
                count = self.class.bucket.incr("#{self.class.design_document}:#{CLUSTER_ID}:count", :create => true)     # This models current id count
                if count == 0 || overflow.nil?
                    overflow ||= 0
                    overflow += 1
                    # We shouldn't need to worry about concurrency here due to the size of count
                    # Would require ~18446744073709551615 concurrent writes
                    self.class.bucket.set("#{self.class.design_document}:#{CLUSTER_ID}:overflow", overflow)
                    self.class.__overflow__ = overflow
                end
                
                self.id = self.class.__class_id_generator__.call(overflow, count)
                
                
                #
                # So an existing id would only be present if:
                # => something crashed before incrementing the overflow
                # => this is another request was occurring before the overflow is incremented
                #
                # Basically only the overflow should be able to cause issues, we'll increment the count just to be sure
                # One would hope this code only ever runs under high load during an overflow event
                #
                while self.class.bucket.get(self.id, :quiet => true).present?
                    # Set in-case we are here due to a crash (concurrency is not an issue)
                    # Note we are not incrementing the @__overflow__ variable
                    self.class.bucket.set("#{self.class.design_document}:#{CLUSTER_ID}:overflow", overflow + 1)
                    count = self.class.bucket.incr("#{self.class.design_document}:#{CLUSTER_ID}:count")               # Increment just in case (attempt to avoid infinite loops)
                    
                    # Reset the overflow
                    if self.class.__overflow__ == overflow
                        self.class.__overflow__ = nil
                    end

                    # Generate the new id
                    self.id = self.class.__class_id_generator__.call(overflow + 1, count)
                end
            end
        end

        def self.included(base)
            class << base
                attr_accessor :__overflow__
                attr_accessor :__class_id_generator__
            end


            base.class_eval do
                #
                # Best case we have 18446744073709551615 * 18446744073709551615 model entries for each database cluster
                #  and we can always change the cluster id if this limit is reached
                #
                define_model_callbacks :save, :create
                before_save :generate_id
                before_create :generate_id

                def self.default_class_id_generator(overflow, count)
                    id = Radix.convert([overflow, CLUSTER_ID].join.to_i, B10, B65) + Radix.convert(count, B10, B65)
                    "#{self.design_document}-#{id}"
                end

                #
                # Override the default hashing function
                #
                def self.set_class_id_generator(callback = nil, &block)
                    callback ||= block
                    self.__class_id_generator__ = callback
                end

                #
                # Configure class level variables
                base.__overflow__ = nil
                base.__class_id_generator__ = method(:default_class_id_generator)
            end
        end
    end # END:: Generator
end
