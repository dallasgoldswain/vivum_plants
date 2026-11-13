# A plant's guidance switches (ST01–ST04, D138–D140). A new plant copies the account's current
# defaults and remembers that revision; later default changes never touch it until the
# collector applies them.
module Plant::Guidance
  extend ActiveSupport::Concern

  included do
    belongs_to :guidance_revision

    before_validation :copy_guidance_defaults, on: :create
    validate { errors.add(:guidance_revision, "must be yours") if guidance_revision && guidance_revision.user_id != user_id }
  end

  # :changed when its switches differ from the revision it copied, else :matches when that
  # revision is the current one, else :older (D139).
  def guidance_status(defaults = user.guidance_defaults)
    if guidance_library != guidance_revision.library || guidance_ai != guidance_revision.ai
      :changed
    elsif guidance_revision_id == defaults.id
      :matches
    else
      :older
    end
  end

  # Copies the current defaults onto this plant; nothing else changes (ST04, D140).
  def apply_guidance_defaults!(defaults = user.guidance_defaults)
    update!(guidance_library: defaults.library, guidance_ai: defaults.ai, guidance_revision: defaults)
  end

  private
    def copy_guidance_defaults
      return if guidance_revision || user.nil?

      defaults = user.guidance_defaults
      self.guidance_revision = defaults
      self.guidance_library = defaults.library
      self.guidance_ai = defaults.ai
    end
end
