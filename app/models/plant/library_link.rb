# A plant's link to a profile in its owner's library (PL01, D151), and the suggestions it
# brings when the plant's library switch is on (D145). A linked profile never changes the
# plant's own names or notes.
module Plant::LibraryLink
  extend ActiveSupport::Concern

  included do
    belongs_to :library_profile, optional: true
    has_many :library_dismissals, dependent: :delete_all

    validate { errors.add(:library_profile, "must be in your library") if library_profile && library_profile.user_id != user_id }
  end

  # The collector's own profile matching this plant's botanical name, else a published
  # platform one to copy (D151).
  def library_match
    return if library_profile || botanical_name.blank?

    user.library_profiles.matching(botanical_name).by_name.first || LibraryProfile.published.matching(botanical_name).by_name.first
  end

  def library_suggestions = (LibraryProfile::PlantSuggestions.new(self) if library_profile && guidance_library?)
end
