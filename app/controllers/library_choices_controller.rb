# The Today card that asks whether to use library suggestions (ST06, D146). Yes saves new
# defaults with the library on and offers to apply them to existing plants; No changes
# nothing. Either way the card goes.
class LibraryChoicesController < ApplicationController
  requires_capability "care.library_guidance"
  skip_verify_authorized # acts only on Current.user

  def create
    Current.user.update!(library_choice_at: Time.current)
    if params[:use_library] == "1"
      Current.user.save_guidance_defaults!(library: true)
      if Current.user.plants.where.not(guidance_revision: Current.user.guidance_defaults).exists?
        redirect_to new_guidance_application_path(status: "all"), notice: "Plants you add will use library suggestions. Choose existing plants to update too."
      else
        redirect_to root_path, notice: "Plants you add will use library suggestions."
      end
    else
      redirect_to root_path, notice: "No problem. You can turn library suggestions on in Account → Guidance settings."
    end
  end
end
