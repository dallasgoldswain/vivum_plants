# A plant that was in the environment when its maintenance happened (EN04, D123).
class EnvironmentEventPlant < ApplicationRecord
  belongs_to :environment_event
  belongs_to :plant
end
