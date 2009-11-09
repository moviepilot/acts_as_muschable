require 'acts_as_muschable'

ActiveRecord::Base.send :include, ActiveRecord::Acts::Muschable

RAILS_DEFAULT_LOGGER.info "** acts_as_muschable: initialized properly."