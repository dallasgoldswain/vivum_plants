# Settings → Guidance: the defaults new plants copy, and their past revisions (ST01–ST03,
# D135, D137). Saving adds a revision; existing plants keep theirs.
class Settings::GuidanceController < ApplicationController
  requires_capability "care.guidance_settings"
  skip_verify_authorized # acts only on Current.user

  def show
    @defaults = Current.user.guidance_defaults
    @revisions = Current.user.guidance_revisions.newest_first
    @plant_counts = Current.user.plants.group(:guidance_revision_id).count
  end

  def update
    switches = { library: params[:library] == "1" }
    switches[:ai] = params[:ai] == "1" if capability?("care.ai_guidance")
    before = Current.user.guidance_defaults
    saved = Current.user.save_guidance_defaults!(**switches)
    notice = saved == before ? "Nothing changed." : "Defaults saved. Plants you add from now on will use them."
    redirect_to settings_guidance_path, notice: notice
  end
end
