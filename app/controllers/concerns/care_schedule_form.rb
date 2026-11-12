# What the reminder form sends (CA02, D112): what, once or every N days, weeks or months,
# after-completion or fixed, and a start date.
module CareScheduleForm
  extend ActiveSupport::Concern

  private
    def schedule_attributes
      attributes = params.fetch(:care_schedule, {}).permit(:kind, :label, :note, :repeats, :interval, :interval_unit, :mode, :starts_on)
      repeats = attributes.delete(:repeats) != "once"
      attributes.to_h.symbolize_keys.merge(
        starts_on: date_param(attributes[:starts_on]),
        interval: (attributes[:interval].presence if repeats),
        interval_unit: (attributes[:interval_unit] if repeats)
      )
    end

    # A new reminder, prefilled from what was just logged (D112) or a sensible default.
    def default_schedule(plant)
      kind = params[:kind].presence_in(CareSchedule::KINDS) || "watering"
      starts_on = params[:from].present? ? date_param(params[:from]) + 7 : Date.current
      (plant&.care_schedules || Current.user.care_schedules).new(kind: kind, label: params[:label], interval: 7, interval_unit: "day", mode: "after_completion", starts_on: starts_on)
    end
end
