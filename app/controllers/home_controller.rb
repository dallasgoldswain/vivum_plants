# The signed-in home page. With reminders on it's Today (CA04, D111, D115): due and overdue
# tasks grouped by kind, the next 7 days, and what's snoozed, then invites and businesses.
class HomeController < ApplicationController
  skip_verify_authorized

  def show
    @memberships = Current.user.memberships.includes(:seller)
    @invitations = capability?("seller.invites") ? Invitation.pending.for_email(Current.user.email_address).includes(:seller) : Invitation.none
    load_today if capability?("care.reminders")
  end

  private
    def load_today
      today = Date.current
      tasks = Current.user.care_tasks.includes(:plant, :care_schedule).order(:due_on, :id)
      visible = tasks.visible_on(today).to_a
      @due_groups = group(visible.select { it.due_on <= today })
      @upcoming_groups = group(visible.select { it.due_on > today && it.due_on <= today + 7 })
      @snoozed = tasks.snoozed_on(today).to_a
    end

    # "Water · 5 plants": by kind, and by label for your own kinds (D115).
    def group(tasks)
      tasks.group_by { [ it.kind, it.label.to_s.downcase ] }.values.sort_by { |list| [ list.first.due_on, helpers.care_task_title(list.first) ] }
    end
end
