class PropertyElement < ActiveRecord::Base
  belongs_to :property
  belongs_to :element
end

