# One ingredient and its quantity in a recipe version, in parts or % (SU02).
class RecipeComponent < ApplicationRecord
  belongs_to :recipe_version, inverse_of: :components
  belongs_to :ingredient

  validates :quantity, numericality: { greater_than: 0, less_than: 1_000_000 }
end
