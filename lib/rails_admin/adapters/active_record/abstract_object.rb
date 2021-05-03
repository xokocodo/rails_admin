module RailsAdmin
  module Adapters
    module ActiveRecord
      class AbstractObject
        # undef almost all of this class's methods so it will pass almost
        # everything through to its delegate using method_missing (below).
        instance_methods.each { |m| undef_method m unless m.to_s =~ /(^__|^send$|^object_id$)/ }
        #                                                  ^^^^^
        # the unnecessary "to_s" above is a workaround for meta_where, see
        # https://github.com/sferik/rails_admin/issues/374

        attr_accessor :object

        def initialize(object)
          self.object = object
        end

        def set_attributes(attributes)
          safe_attributes = attributes&.to_h do |k, v|
            if (m = k.match(/([a-zA-Z_]+)_attributes/)) && (klass = object.class.embedded_relations[m[1]]&.klass)
              if klass.fields[:_id].default_val.nil?
                value = v.transform_values { |v2| v2.except(:id) }
                object[m[1]] = []
              else
                value = v
              end
            else
              value = v
            end
            [k, value]
          end
          object.assign_attributes(safe_attributes) if safe_attributes
        end

        def save(options = {validate: true})
          object.save(**options)
        end

        if RUBY_VERSION >= '2.7'
          def method_missing(method_name, *args, **kwargs, &block)
            object.send(method_name, *args, **kwargs, &block)
          end
        else
          def method_missing(method_name, *args, &block)
            object.send(method_name, *args, &block)
          end
        end
      end
    end
  end
end
