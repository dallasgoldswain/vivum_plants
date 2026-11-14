# A care profile for a species (GU01, D141–D154). Platform profiles (no owner) are published
# through numbered versions, and their row holds the published content for searching and
# copying. A collector's own profiles (user) are edited directly; sellers' come with B31.
class LibraryProfile < ApplicationRecord
  include Contents

  belongs_to :user, optional: true
  belongs_to :seller, optional: true
  has_many :versions, -> { order(:number) }, class_name: "LibraryProfileVersion", dependent: :destroy, inverse_of: :library_profile
  has_one :published_version, -> { where(status: "published") }, class_name: "LibraryProfileVersion"
  has_many :plants, dependent: :nullify
  has_many :care_schedules, dependent: :nullify
  has_many :dismissals, class_name: "LibraryDismissal", dependent: :delete_all

  scope :platform, -> { where(user_id: nil, seller_id: nil) }
  # Platform profiles with a published version; drafts and retired ones are never shown (D141).
  scope :published, -> { platform.where(id: LibraryProfileVersion.where(status: "published").select(:library_profile_id)) }
  scope :by_name, -> { order(Arel.sql("LOWER(botanical_name)")) }
  # Botanical name or a synonym, ignoring case (D151).
  scope :matching, ->(name) {
    name = name.to_s.squish.downcase
    name.empty? ? none : where("LOWER(botanical_name) = :name OR EXISTS (SELECT 1 FROM unnest(synonyms) AS s WHERE LOWER(s) = :name)", name: name)
  }
  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.squish.downcase)}%"
    query.blank? ? all : where("LOWER(botanical_name) LIKE :term OR LOWER(COALESCE(family, '')) LIKE :term OR EXISTS (SELECT 1 FROM unnest(synonyms || common_names) AS n WHERE LOWER(n) LIKE :term)", term: term)
  }
  scope :covering, ->(context) { Plant::GROWING_CONTEXTS.include?(context) ? where("content ? :context", context: context) : all }

  validates :key, uniqueness: true, allow_nil: true, format: { with: /\A[a-z0-9_]+\z/ }
  validate { errors.add(:key, "is for platform profiles only") if key && !platform? }

  # Personal edits to the care content flag linked plants for review (D152).
  before_save { self.content_edited_at = Time.current if platform? == false && (new_record? || will_save_change_to_content?) }

  def platform? = user_id.nil? && seller_id.nil?
  def personal? = user_id.present?

  # Copies a published platform profile into a collector's library. The copy is theirs to
  # edit and keeps no link to its source (D150).
  def copy_for!(owner)
    raise ArgumentError, "only published platform profiles can be copied" unless platform? && published_version

    owner.library_profiles.create!(slice(:botanical_name, :synonyms, :common_names, :family, :content, :references))
  end

  # Called when a version is published: the row mirrors it for searching and copying.
  def mirror!(version)
    update!(version.slice(:botanical_name, :synonyms, :common_names, :family, :content, :references))
  end
end
