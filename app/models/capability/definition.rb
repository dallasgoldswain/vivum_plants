# One registered capability from config/features.yml.
Capability::Definition = Data.define(:key, :domain, :state, :implemented, :depends_on, :entitlement, :description, :off, :internal) do
  def implemented? = implemented
  def roadmap? = state == "roadmap"
  def internal? = internal
end
