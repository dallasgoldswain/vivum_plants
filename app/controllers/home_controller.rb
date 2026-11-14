# The signed-in home page. With reminders on it's Today (CA04, D111, D115, D125): due and
# overdue tasks grouped by kind, environments before plants, the next 7 days, and what's
# snoozed, then invites and businesses.
class HomeController < ApplicationController
  skip_verify_authorized

  def show
    @memberships = Current.user.memberships.includes(:seller)
    @invitations = capability?("seller.invites") ? Invitation.pending.for_email(Current.user.email_address).includes(:seller) : Invitation.none
    load_today if capability?("care.reminders")
    load_library if capability?("care.library_guidance")
  end

  private
    def load_today
      today = Date.current
      tasks = Current.user.care_tasks.includes(:plant, :environment, :care_schedule).order(:due_on, :id)
      visible = tasks.visible_on(today).to_a
      @due_groups = group(visible.select { it.due_on <= today })
      @upcoming_groups = group(visible.select { it.due_on > today && it.due_on <= today + 7 })
      @snoozed = tasks.snoozed_on(today).to_a
    end

    # The library choice card until answered (D146), and plants with suggestions to review (D145).
    def load_library
      @library_choice = Current.user.library_choice_at.nil?
      @suggestion_plants = Current.user.plants.in_active_collection.where(guidance_library: true).where.not(library_profile_id: nil)
        .includes(:library_profile, :care_schedules, :library_dismissals).order(:display_name, :number)
        .select { it.library_suggestions.pending.any? }
    end

    # "Water · 5 plants": by kind, and by label for your own kinds (D115). Environment tasks
    # come first, one per environment, never per plant (D125).
    def group(tasks)
      tasks.group_by { [ it.environment_id ? 0 : 1, it.kind, it.label.to_s.downcase ] }
        .sort_by { |(environment, _, _), list| [ environment, list.first.due_on, helpers.care_task_title(list.first) ] }.map(&:last)
    end
end
