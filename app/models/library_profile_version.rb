# One version of a platform profile (D141): draft → in review → published → retired. Only
# one version is published at a time, and a published or retired version is never edited;
# a correction is a new version.
class LibraryProfileVersion < ApplicationRecord
  include LibraryProfile::Contents

  STATUSES = %w[ draft in_review published retired ].freeze

  belongs_to :library_profile
  belongs_to :published_by, class_name: "User", optional: true

  enum :status, STATUSES.index_by(&:itself), validate: true, default: "draft"

  before_validation { self.number ||= (library_profile.versions.maximum(:number) || 0) + 1 if library_profile }
  validate { errors.add(:base, "A published or retired version can't be changed") if persisted? && (status_was.in?(%w[ published retired ])) && (changed & %w[ botanical_name synonyms common_names family content references reviewed_on ]).any? }

  def editable? = draft? || in_review?

  def submit! = update!(status: "in_review")
  def back_to_draft! = update!(status: "draft")

  # Publishing retires the version it replaces and mirrors the content onto the profile.
  def publish!(by:)
    raise ArgumentError, "only a version in review can be published" unless in_review?

    transaction do
      library_profile.versions.published.where.not(id: id).find_each { it.update!(status: "retired") }
      update!(status: "published", published_at: Time.current, published_by: by, reviewed_on: reviewed_on || Date.current)
      library_profile.mirror!(self)
    end
  end

  # Retiring the published version hides the profile from collectors until another is published.
  def retire! = update!(status: "retired")

  # A new draft starting from this version's content.
  def next_draft
    library_profile.versions.new(slice(:botanical_name, :synonyms, :common_names, :family, :content, :references))
  end
end
