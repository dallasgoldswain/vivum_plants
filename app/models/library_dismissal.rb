# A suggested reminder a collector dismissed for one plant (GU03, D145). It counts until the
# profile's content is next edited.
class LibraryDismissal < ApplicationRecord
  belongs_to :user
  belongs_to :plant
  belongs_to :library_profile
end
