# One registered capability from config/features.yml.
Capability::Definition = Data.define(:key, :domain, :state, :implemented, :depends_on, :entitlement, :description, :off) do
  def implemented? = implemented
  def roadmap? = state == "roadmap"
end
