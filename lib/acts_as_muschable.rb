module ActiveRecord
  module Acts
    module Muschable
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_muschable(*args)
          
        end
      end
      
    end
  end
end