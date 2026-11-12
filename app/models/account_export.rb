require "zip"

# A machine-readable export of everything VIVUM holds about one account (PRD §26, D68).
# A zip of JSON files, one per section, plus a manifest and a README.
#
# Each domain adds its own section to SECTIONS as it ships.
# A section returns plain data about this user only; never other people's personal data.
class AccountExport
  FORMAT_VERSION = 1

  SECTIONS = {
    "account" => ->(user) {
      user.slice(:id, :email_address, :email_verified_at, :created_at).merge(
        two_step_sign_in: user.two_factor_enabled?, platform_operator: user.platform_operator?
      )
    },
    "sessions" => ->(user) {
      user.sessions.order(:created_at).map { it.slice(:created_at, :updated_at, :ip_address, :user_agent) }
    },
    "memberships" => ->(user) {
      user.memberships.includes(:seller).order(:created_at).map { { seller: it.seller.name, role: it.role, since: it.created_at } }
    },
    "consents" => ->(user) {
      user.consent_records.chronological.map { it.slice(:purpose, :version, :granted, :source, :ip_address, :user_agent, :created_at) }
    },
    # Invitees' email addresses are their personal data, so only the invite itself is listed.
    "invitations_sent" => ->(user) {
      Invitation.where(invited_by: user).order(:created_at).map { { business: it.business_label, kind: it.kind, role: it.role, status: it.status, created_at: it.created_at } }
    },
    "invitations_received" => ->(user) {
      Invitation.for_email(user.email_address).order(:created_at).map { { business: it.business_label, kind: it.kind, role: it.role, status: it.status, created_at: it.created_at } }
    },
    "referrals" => ->(user) {
      { codes: user.referral_codes.map { it.slice(:code, :referrals_count, :visits_count, :created_at) }, referred_by_a_code: user.referral.present? }
    },
    "notifications" => ->(user) {
      user.notifications.order(:created_at).map { it.slice(:type, :created_at, :read_at, :seen_at) }
    },
    "data_requests" => ->(user) {
      user.data_requests.order(:created_at).map { it.slice(:kind, :status, :message, :outcome, :due_on, :created_at, :completed_at) }
    },
    "plants" => ->(user) {
      user.plants.includes(:acquisition, :status_changes).order(:number).map do |plant|
        plant.slice(:number, :display_name, :botanical_name, :cultivar, :common_name, :nickname, :growing_context, :tc_origin, :origin_note, :quantity, :notes, :tags, :status, :status_on, :created_at, :updated_at).merge(
          record_id: plant.record_id,
          acquisition: plant.acquisition&.slice(:acquired_on, :source, :cost_cents, :currency, :order_reference, :quantity, :arrival_notes),
          status_history: plant.status_changes.map { it.slice(:status, :effective_on, :reason, :created_at) }
        )
      end
    },
    "care_events" => ->(user) {
      user.care_events.includes(:plant, :environment, :from_environment).order(:occurred_at).map do |event|
        event.slice(:kind, :note, :occurred_at, :created_at).merge(plant: event.plant.record_id, moved_to: event.environment&.name, moved_from: event.from_environment&.name).compact
      end
    },
    "photos" => ->(user) {
      user.photos.includes(:plant, :environment, image_attachment: :blob).order(:id).map do |photo|
        photo.slice(:caption, :taken_on, :created_at).merge(plant: photo.plant&.record_id, environment: photo.environment&.name, file: AccountExport.photo_path(photo)).compact
      end
    },
    "environments" => ->(user) {
      user.environments.includes(assignments: :plant).order(:id).map do |environment|
        environment.slice(:id, :name, :kind, :notes, :length_cm, :width_cm, :height_cm, :volume_litres, :status, :created_at, :updated_at).merge(
          occupants: environment.assignments.sort_by(&:started_on).map { { plant: it.plant.record_id, moved_in: it.started_on, moved_out: it.ended_on } }
        )
      end
    },
    "plant_setups" => ->(user) {
      user.plant_setups.includes(:plant).order(:started_on, :id).map { it.slice(:started_on, :container, :size, :size_unit, :watering_method, :created_at).merge(plant: it.plant.record_id) }
    },
    "measurements" => ->(user) {
      user.measurements.includes(:environment, values: :custom_metric).order(:measured_at).map do |measurement|
        measurement.slice(:measured_at, :source, :note, :created_at).merge(
          environment: measurement.environment.name,
          values: measurement.values.map { { metric: it.label, value: it.value, text: it.text_value, unit: it.unit }.compact }
        )
      end
    },
    "custom_metrics" => ->(user) {
      user.custom_metrics.by_name.map { it.slice(:name, :unit, :created_at) }
    }
  }.freeze

  # Photo files go in the zip beside photos.json (D68).
  def self.photo_path(photo)
    subject = photo.plant ? photo.plant.record_id : "environment-#{photo.environment_id}"
    "photos/#{subject}-#{photo.id}.jpg"
  end

  def initialize(user)
    @user = user
  end

  def filename = "vivum-export-#{Date.current.iso8601}.zip"

  # The zip as a binary string.
  def to_zip
    buffer = Zip::OutputStream.write_buffer do |zip|
      write(zip, "README.txt", readme)
      write(zip, "manifest.json", JSON.pretty_generate(manifest))
      SECTIONS.each { |name, section| write(zip, "#{name}.json", JSON.pretty_generate(section.call(@user))) }
      @user.photos.includes(:plant, image_attachment: :blob).find_each do |photo|
        write(zip, self.class.photo_path(photo), photo.image.download) if photo.image.attached?
      end
    end
    buffer.string
  end

  private
    def write(zip, name, content)
      zip.put_next_entry(name)
      zip.write(content)
    end

    def manifest
      { format_version: FORMAT_VERSION, generated_at: Time.current, account_id: @user.id, sections: SECTIONS.keys.map { "#{it}.json" } }
    end

    def readme
      <<~TEXT
        Your VIVUM Plants data, exported on #{Time.current.to_fs(:long)}.

        Each .json file is one part of your account; manifest.json lists them. Times are UTC.
        To correct anything here, or ask what else we hold, use Settings → Privacy.
      TEXT
    end
end
