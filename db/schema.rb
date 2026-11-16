# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_16_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "acquisitions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "acquired_on"
    t.string "source"
    t.integer "cost_cents"
    t.string "currency", limit: 3, default: "ZAR", null: false
    t.string "order_reference"
    t.integer "quantity"
    t.text "arrival_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.boolean "tissue_culture", default: false, null: false
    t.string "container_condition"
    t.date "deflasked_on"
    t.bigint "cover_photo_id"
    t.index ["user_id"], name: "index_acquisitions_on_user_id"
    t.check_constraint "cost_cents IS NULL OR cost_cents >= 0", name: "acquisitions_cost_not_negative"
    t.check_constraint "quantity IS NULL OR quantity >= 0", name: "acquisitions_quantity_not_negative"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.string "target_key"
    t.jsonb "details", default: {}, null: false
    t.text "reason"
    t.string "ip_address"
    t.string "user_agent"
    t.string "request_id"
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["actor_id"], name: "index_audit_events_on_actor_id"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["target_key"], name: "index_audit_events_on_target_key"
    t.index ["target_type", "target_id"], name: "index_audit_events_on_target_type_and_target_id"
  end

  create_table "buyer_addresses", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.string "label"
    t.string "recipient", null: false
    t.string "street", null: false
    t.string "suburb"
    t.string "city", null: false
    t.string "province", null: false
    t.string "postal_code", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_buyer_addresses_on_buyer_id"
  end

  create_table "buyer_aliases", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "buyer_id"
    t.string "name", null: false
    t.string "group_name"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_buyer_aliases_on_buyer_id"
    t.index ["created_by_id"], name: "index_buyer_aliases_on_created_by_id"
    t.index ["seller_id"], name: "index_buyer_aliases_on_seller_id"
  end

  create_table "buyer_consents", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.string "purpose", null: false
    t.string "version", null: false
    t.boolean "granted", null: false
    t.string "source", null: false
    t.string "method"
    t.datetime "given_at", null: false
    t.bigint "recorded_by_id"
    t.datetime "created_at", null: false
    t.index ["buyer_id", "purpose", "created_at"], name: "index_buyer_consents_on_buyer_id_and_purpose_and_created_at"
    t.index ["buyer_id"], name: "index_buyer_consents_on_buyer_id"
    t.index ["recorded_by_id"], name: "index_buyer_consents_on_recorded_by_id"
  end

  create_table "buyer_verifications", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.string "token_digest", null: false
    t.string "phone", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "revoked_at"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_buyer_verifications_on_buyer_id"
    t.index ["created_by_id"], name: "index_buyer_verifications_on_created_by_id"
    t.index ["token_digest"], name: "index_buyer_verifications_on_token_digest", unique: true
  end

  create_table "buyers", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.string "contact_preference", default: "whatsapp", null: false
    t.datetime "verified_at"
    t.string "verification_method"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "phone"], name: "index_buyers_on_seller_id_and_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["seller_id"], name: "index_buyers_on_seller_id"
    t.check_constraint "phone IS NOT NULL OR deleted_at IS NOT NULL", name: "buyers_phone_unless_deleted"
  end

  create_table "care_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id", null: false
    t.string "kind", default: "observation", null: false
    t.text "note"
    t.datetime "occurred_at", null: false
    t.string "idempotency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "environment_id"
    t.bigint "from_environment_id"
    t.bigint "plant_setup_id"
    t.decimal "amount", precision: 10, scale: 3
    t.string "amount_unit"
    t.string "watering_method"
    t.string "product"
    t.string "strength"
    t.string "target"
    t.string "label"
    t.bigint "care_task_id"
    t.string "stage"
    t.boolean "new_leaves", default: false, null: false
    t.boolean "new_roots", default: false, null: false
    t.boolean "damage", default: false, null: false
    t.boolean "suspected_contamination", default: false, null: false
    t.string "humidity_setup"
    t.index ["care_task_id"], name: "index_care_events_on_care_task_id", unique: true
    t.index ["environment_id"], name: "index_care_events_on_environment_id"
    t.index ["from_environment_id"], name: "index_care_events_on_from_environment_id"
    t.index ["plant_id", "kind", "occurred_at"], name: "index_care_events_on_plant_id_and_kind_and_occurred_at"
    t.index ["plant_id", "occurred_at"], name: "index_care_events_on_plant_id_and_occurred_at"
    t.index ["plant_id"], name: "index_care_events_on_plant_id"
    t.index ["plant_setup_id"], name: "index_care_events_on_plant_setup_id"
    t.index ["user_id", "idempotency_key"], name: "index_care_events_on_user_id_and_idempotency_key", unique: true
    t.index ["user_id"], name: "index_care_events_on_user_id"
    t.check_constraint "amount IS NULL OR amount > 0::numeric", name: "care_events_amount_positive"
  end

  create_table "care_schedules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id"
    t.string "kind", null: false
    t.string "label"
    t.string "note"
    t.integer "interval"
    t.string "interval_unit"
    t.string "mode", default: "after_completion", null: false
    t.date "starts_on", null: false
    t.string "status", default: "active", null: false
    t.boolean "paused_by_status", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "environment_id"
    t.string "origin"
    t.bigint "library_profile_id"
    t.datetime "library_synced_at"
    t.index ["environment_id"], name: "index_care_schedules_on_environment_id"
    t.index ["library_profile_id"], name: "index_care_schedules_on_library_profile_id"
    t.index ["plant_id"], name: "index_care_schedules_on_plant_id"
    t.index ["user_id"], name: "index_care_schedules_on_user_id"
    t.check_constraint "\"interval\" IS NULL OR \"interval\" > 0 AND (interval_unit::text = ANY (ARRAY['day'::character varying, 'week'::character varying, 'month'::character varying]::text[]))", name: "care_schedules_interval_valid"
    t.check_constraint "num_nonnulls(plant_id, environment_id) = 1", name: "care_schedules_one_subject"
  end

  create_table "care_tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id"
    t.bigint "care_schedule_id", null: false
    t.date "due_on", null: false
    t.boolean "due_on_changed_by_hand", default: false, null: false
    t.date "snoozed_until"
    t.string "state", default: "open", null: false
    t.datetime "resolved_at"
    t.date "resolved_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "environment_id"
    t.index ["care_schedule_id"], name: "index_care_tasks_on_care_schedule_id"
    t.index ["care_schedule_id"], name: "index_care_tasks_one_open_per_schedule", unique: true, where: "((state)::text = 'open'::text)"
    t.index ["environment_id"], name: "index_care_tasks_on_environment_id"
    t.index ["plant_id"], name: "index_care_tasks_on_plant_id"
    t.index ["user_id", "state", "due_on"], name: "index_care_tasks_on_user_id_and_state_and_due_on"
    t.index ["user_id"], name: "index_care_tasks_on_user_id"
    t.check_constraint "num_nonnulls(plant_id, environment_id) = 1", name: "care_tasks_one_subject"
  end

  create_table "consent_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "purpose", null: false
    t.string "version", null: false
    t.boolean "granted", null: false
    t.string "source", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["user_id", "purpose", "created_at"], name: "index_consent_records_on_user_id_and_purpose_and_created_at"
  end

  create_table "custom_metrics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, lower((name)::text)", name: "index_custom_metrics_on_user_and_name", unique: true
    t.index ["user_id"], name: "index_custom_metrics_on_user_id"
  end

  create_table "data_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.string "status", default: "open", null: false
    t.text "message"
    t.text "outcome"
    t.date "due_on", null: false
    t.bigint "handled_by_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["handled_by_id"], name: "index_data_requests_on_handled_by_id"
    t.index ["status", "due_on"], name: "index_data_requests_on_status_and_due_on"
    t.index ["user_id"], name: "index_data_requests_on_user_id"
  end

  create_table "environment_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id", null: false
    t.bigint "environment_id", null: false
    t.date "started_on", null: false
    t.date "ended_on"
    t.boolean "context_answered", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["environment_id"], name: "index_environment_assignments_on_environment_id"
    t.index ["plant_id"], name: "index_environment_assignments_on_plant_id"
    t.index ["plant_id"], name: "index_environment_assignments_one_current", unique: true, where: "(ended_on IS NULL)"
    t.index ["user_id"], name: "index_environment_assignments_on_user_id"
    t.check_constraint "ended_on IS NULL OR ended_on >= started_on", name: "environment_assignments_dates_in_order"
  end

  create_table "environment_event_plants", force: :cascade do |t|
    t.bigint "environment_event_id", null: false
    t.bigint "plant_id", null: false
    t.index ["environment_event_id", "plant_id"], name: "idx_on_environment_event_id_plant_id_5309da0dcf", unique: true
    t.index ["environment_event_id"], name: "index_environment_event_plants_on_environment_event_id"
    t.index ["plant_id"], name: "index_environment_event_plants_on_plant_id"
  end

  create_table "environment_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "environment_id", null: false
    t.bigint "care_task_id"
    t.string "kind", null: false
    t.string "label"
    t.datetime "occurred_at", null: false
    t.text "note"
    t.decimal "amount", precision: 10, scale: 3
    t.string "amount_unit"
    t.string "product"
    t.string "idempotency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["care_task_id"], name: "index_environment_events_on_care_task_id", unique: true
    t.index ["environment_id", "occurred_at"], name: "index_environment_events_on_environment_id_and_occurred_at"
    t.index ["environment_id"], name: "index_environment_events_on_environment_id"
    t.index ["user_id", "idempotency_key"], name: "index_environment_events_on_user_id_and_idempotency_key", unique: true
    t.index ["user_id"], name: "index_environment_events_on_user_id"
    t.check_constraint "amount IS NULL OR amount > 0::numeric", name: "environment_events_amount_positive"
  end

  create_table "environments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "kind", null: false
    t.text "notes"
    t.decimal "length_cm", precision: 7, scale: 1
    t.decimal "width_cm", precision: 7, scale: 1
    t.decimal "height_cm", precision: 7, scale: 1
    t.decimal "volume_litres", precision: 8, scale: 1
    t.string "status", default: "active", null: false
    t.bigint "cover_photo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_environments_on_user_id_and_status"
    t.index ["user_id"], name: "index_environments_on_user_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "guidance_revisions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "number", null: false
    t.boolean "library", default: false, null: false
    t.boolean "ai", default: false, null: false
    t.datetime "created_at", null: false
    t.index ["user_id", "number"], name: "index_guidance_revisions_on_user_id_and_number", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.bigint "user_id"
    t.string "key"
    t.bigint "copied_from_id"
    t.string "name", null: false
    t.string "manufacturer"
    t.string "category", null: false
    t.string "water_retention"
    t.string "aeration"
    t.decimal "particle_min_mm", precision: 5, scale: 1
    t.decimal "particle_max_mm", precision: 5, scale: 1
    t.text "intended_use"
    t.text "preparation"
    t.string "source"
    t.text "notes"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["copied_from_id"], name: "index_ingredients_on_copied_from_id"
    t.index ["key"], name: "index_ingredients_on_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["user_id", "status"], name: "index_ingredients_on_user_id_and_status"
    t.index ["user_id"], name: "index_ingredients_on_user_id"
    t.check_constraint "(user_id IS NULL) = (key IS NOT NULL)", name: "ingredients_built_in_or_personal"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "kind", null: false
    t.string "email_address", null: false
    t.string "role", null: false
    t.bigint "seller_id"
    t.string "business_name"
    t.bigint "invited_by_id"
    t.bigint "accepted_by_id"
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_invitations_on_accepted_by_id"
    t.index ["email_address"], name: "index_invitations_on_email_address"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["seller_id"], name: "index_invitations_on_seller_id"
  end

  create_table "library_dismissals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id", null: false
    t.bigint "library_profile_id", null: false
    t.string "kind", null: false
    t.string "label"
    t.datetime "created_at", null: false
    t.index ["library_profile_id"], name: "index_library_dismissals_on_library_profile_id"
    t.index ["plant_id"], name: "index_library_dismissals_on_plant_id"
    t.index ["user_id"], name: "index_library_dismissals_on_user_id"
  end

  create_table "library_profile_versions", force: :cascade do |t|
    t.bigint "library_profile_id", null: false
    t.integer "number", null: false
    t.string "status", default: "draft", null: false
    t.string "botanical_name", null: false
    t.string "synonyms", default: [], null: false, array: true
    t.string "common_names", default: [], null: false, array: true
    t.string "family"
    t.jsonb "content", default: {}, null: false
    t.jsonb "references", default: [], null: false
    t.date "reviewed_on"
    t.datetime "published_at"
    t.bigint "published_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["library_profile_id", "number"], name: "idx_on_library_profile_id_number_4ab0113fd0", unique: true
    t.index ["library_profile_id"], name: "index_library_profile_versions_one_published", unique: true, where: "((status)::text = 'published'::text)"
    t.index ["published_by_id"], name: "index_library_profile_versions_on_published_by_id"
  end

  create_table "library_profiles", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "seller_id"
    t.string "key"
    t.string "botanical_name", null: false
    t.string "synonyms", default: [], null: false, array: true
    t.string "common_names", default: [], null: false, array: true
    t.string "family"
    t.jsonb "content", default: {}, null: false
    t.jsonb "references", default: [], null: false
    t.datetime "content_edited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_library_profiles_on_key", unique: true, where: "(key IS NOT NULL)"
    t.index ["seller_id"], name: "index_library_profiles_on_seller_id"
    t.index ["user_id"], name: "index_library_profiles_on_user_id"
    t.check_constraint "key IS NULL OR user_id IS NULL AND seller_id IS NULL", name: "library_profiles_key_platform_only"
    t.check_constraint "num_nonnulls(user_id, seller_id) <= 1", name: "library_profiles_one_owner"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "stock_item_id", null: false
    t.integer "number", null: false
    t.string "reference", null: false
    t.string "title", null: false
    t.integer "price_cents", null: false
    t.integer "listed_quantity"
    t.bigint "photo_ids", default: [], null: false, array: true
    t.string "size"
    t.text "details"
    t.text "caption"
    t.string "state", default: "draft", null: false
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "reference"], name: "index_listings_on_seller_id_and_reference", unique: true
    t.index ["seller_id"], name: "index_listings_on_seller_id"
    t.index ["stock_item_id"], name: "index_listings_on_stock_item_id"
    t.index ["stock_item_id"], name: "index_listings_one_live_per_item", unique: true, where: "((state)::text = ANY ((ARRAY['active'::character varying, 'paused'::character varying])::text[]))"
    t.check_constraint "listed_quantity IS NULL OR listed_quantity > 0", name: "listings_listed_quantity_positive"
    t.check_constraint "price_cents >= 0", name: "listings_price_not_negative"
  end

  create_table "measurement_values", force: :cascade do |t|
    t.bigint "measurement_id", null: false
    t.string "metric", null: false
    t.bigint "custom_metric_id"
    t.decimal "value", precision: 10, scale: 2
    t.string "text_value"
    t.string "unit", null: false
    t.index ["custom_metric_id"], name: "index_measurement_values_on_custom_metric_id"
    t.index ["measurement_id", "metric", "custom_metric_id"], name: "index_measurement_values_one_per_metric", unique: true, nulls_not_distinct: true
    t.index ["measurement_id"], name: "index_measurement_values_on_measurement_id"
    t.check_constraint "value IS NOT NULL OR text_value IS NOT NULL", name: "measurement_values_present"
  end

  create_table "measurements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "environment_id", null: false
    t.datetime "measured_at", null: false
    t.string "source", default: "Manual", null: false
    t.string "note"
    t.string "idempotency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["environment_id", "measured_at"], name: "index_measurements_on_environment_id_and_measured_at"
    t.index ["environment_id"], name: "index_measurements_on_environment_id"
    t.index ["user_id", "idempotency_key"], name: "index_measurements_on_user_id_and_idempotency_key", unique: true
    t.index ["user_id"], name: "index_measurements_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "user_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id", "user_id"], name: "index_memberships_on_seller_id_and_user_id", unique: true
    t.index ["seller_id"], name: "index_memberships_on_seller_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying, 'manager'::character varying, 'host_packer'::character varying]::text[])", name: "memberships_role_check"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.bigint "record_id"
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.string "type"
    t.bigint "event_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "otp_backup_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code_digest", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_otp_backup_codes_on_user_id"
  end

  create_table "photos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id"
    t.bigint "care_event_id"
    t.string "caption"
    t.date "taken_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "environment_id"
    t.bigint "environment_event_id"
    t.bigint "acquisition_id"
    t.bigint "stock_item_id"
    t.index ["acquisition_id"], name: "index_photos_on_acquisition_id"
    t.index ["care_event_id"], name: "index_photos_on_care_event_id"
    t.index ["environment_event_id"], name: "index_photos_on_environment_event_id"
    t.index ["environment_id"], name: "index_photos_on_environment_id"
    t.index ["plant_id", "taken_on"], name: "index_photos_on_plant_id_and_taken_on"
    t.index ["plant_id"], name: "index_photos_on_plant_id"
    t.index ["stock_item_id"], name: "index_photos_on_stock_item_id"
    t.index ["user_id"], name: "index_photos_on_user_id"
    t.check_constraint "num_nonnulls(plant_id, environment_id, acquisition_id, stock_item_id) = 1", name: "photos_one_subject"
  end

  create_table "plans", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.integer "monthly_price_cents", null: false
    t.integer "member_limit", null: false
    t.integer "photo_limit", null: false
    t.integer "ai_extractions_per_month", null: false
    t.boolean "paid_branding", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plans_on_key", unique: true
  end

  create_table "plant_setups", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plant_id", null: false
    t.date "started_on", null: false
    t.string "container"
    t.decimal "size", precision: 7, scale: 1
    t.string "size_unit"
    t.string "watering_method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recipe_version_id"
    t.index ["plant_id", "started_on"], name: "index_plant_setups_on_plant_id_and_started_on"
    t.index ["plant_id"], name: "index_plant_setups_on_plant_id"
    t.index ["recipe_version_id"], name: "index_plant_setups_on_recipe_version_id"
    t.index ["user_id"], name: "index_plant_setups_on_user_id"
  end

  create_table "plant_status_changes", force: :cascade do |t|
    t.bigint "plant_id", null: false
    t.string "status", null: false
    t.date "effective_on", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.index ["plant_id"], name: "index_plant_status_changes_on_plant_id"
  end

  create_table "plants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "acquisition_id"
    t.integer "number", null: false
    t.string "display_name", null: false
    t.string "botanical_name"
    t.string "cultivar"
    t.string "common_name"
    t.string "nickname"
    t.string "growing_context", null: false
    t.boolean "tc_origin", default: false, null: false
    t.string "origin_note"
    t.integer "quantity", default: 1, null: false
    t.text "notes"
    t.string "tags", default: [], null: false, array: true
    t.string "status", default: "active", null: false
    t.date "status_on"
    t.bigint "cover_photo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tc_stage"
    t.bigint "split_from_id"
    t.boolean "guidance_library", default: false, null: false
    t.boolean "guidance_ai", default: false, null: false
    t.bigint "guidance_revision_id", null: false
    t.bigint "library_profile_id"
    t.index ["acquisition_id"], name: "index_plants_on_acquisition_id"
    t.index ["guidance_revision_id"], name: "index_plants_on_guidance_revision_id"
    t.index ["library_profile_id"], name: "index_plants_on_library_profile_id"
    t.index ["split_from_id"], name: "index_plants_on_split_from_id"
    t.index ["tags"], name: "index_plants_on_tags", using: :gin
    t.index ["user_id", "number"], name: "index_plants_on_user_id_and_number", unique: true
    t.index ["user_id", "status"], name: "index_plants_on_user_id_and_status"
    t.index ["user_id"], name: "index_plants_on_user_id"
    t.check_constraint "quantity >= 0", name: "plants_quantity_not_negative"
  end

  create_table "recipe_components", force: :cascade do |t|
    t.bigint "recipe_version_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 8, scale: 2, null: false
    t.integer "position", default: 0, null: false
    t.index ["ingredient_id"], name: "index_recipe_components_on_ingredient_id"
    t.index ["recipe_version_id", "ingredient_id"], name: "index_recipe_components_on_recipe_version_id_and_ingredient_id", unique: true
    t.check_constraint "quantity > 0::numeric", name: "recipe_components_quantity_positive"
  end

  create_table "recipe_versions", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.integer "number", null: false
    t.string "basis", null: false
    t.string "state", default: "draft", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "number"], name: "index_recipe_versions_on_recipe_id_and_number", unique: true
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "contexts", default: [], null: false, array: true
    t.string "source"
    t.text "notes"
    t.string "status", default: "active", null: false
    t.string "share_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["share_token"], name: "index_recipes_on_share_token", unique: true, where: "(share_token IS NOT NULL)"
    t.index ["user_id", "status"], name: "index_recipes_on_user_id_and_status"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "refer_referral_codes", force: :cascade do |t|
    t.string "referrer_type", null: false
    t.bigint "referrer_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "referrals_count", default: 0
    t.integer "visits_count", default: 0
    t.index ["code"], name: "index_refer_referral_codes_on_code", unique: true
    t.index ["referrer_type", "referrer_id"], name: "index_refer_referral_codes_on_referrer"
  end

  create_table "refer_referrals", force: :cascade do |t|
    t.string "referrer_type", null: false
    t.bigint "referrer_id", null: false
    t.string "referee_type", null: false
    t.bigint "referee_id", null: false
    t.bigint "referral_code_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at", precision: nil
    t.index ["referee_type", "referee_id"], name: "index_refer_referrals_on_referee_type_and_referee_id", unique: true
    t.index ["referral_code_id"], name: "index_refer_referrals_on_referral_code_id"
    t.index ["referrer_type", "referrer_id"], name: "index_refer_referrals_on_referrer"
  end

  create_table "refer_visits", force: :cascade do |t|
    t.bigint "referral_code_id", null: false
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referral_code_id"], name: "index_refer_visits_on_referral_code_id"
  end

  create_table "sale_cards", force: :cascade do |t|
    t.bigint "listing_id", null: false
    t.string "format", null: false
    t.string "file_type", null: false
    t.integer "price_cents", null: false
    t.string "title", null: false
    t.bigint "photo_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_sale_cards_on_created_by_id"
    t.index ["listing_id"], name: "index_sale_cards_on_listing_id"
  end

  create_table "sellers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "billing_mode", default: "pilot", null: false
    t.bigint "plan_id", null: false
    t.date "free_until"
    t.integer "last_stock_number", default: 0, null: false
    t.integer "last_listing_number", default: 0, null: false
    t.text "listing_details"
    t.index ["plan_id"], name: "index_sellers_on_plan_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "seller_id"
    t.index ["seller_id"], name: "index_sessions_on_seller_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stock_balances", force: :cascade do |t|
    t.bigint "stock_item_id", null: false
    t.bigint "stock_location_id", null: false
    t.integer "saleable", default: 0, null: false
    t.integer "unavailable", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_item_id", "stock_location_id"], name: "index_stock_balances_on_stock_item_id_and_stock_location_id", unique: true
    t.index ["stock_location_id"], name: "index_stock_balances_on_stock_location_id"
    t.check_constraint "saleable >= 0 AND unavailable >= 0", name: "stock_balances_not_negative"
  end

  create_table "stock_holds", force: :cascade do |t|
    t.bigint "stock_item_id", null: false
    t.bigint "stock_location_id", null: false
    t.integer "quantity", null: false
    t.string "held_for", null: false
    t.datetime "expires_at", null: false
    t.string "state", default: "active", null: false
    t.bigint "created_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "buyer_id"
    t.bigint "buyer_alias_id"
    t.index ["buyer_alias_id"], name: "index_stock_holds_on_buyer_alias_id"
    t.index ["buyer_id"], name: "index_stock_holds_on_buyer_id"
    t.index ["created_by_id"], name: "index_stock_holds_on_created_by_id"
    t.index ["expires_at"], name: "index_stock_holds_active_expiry", where: "((state)::text = 'active'::text)"
    t.index ["stock_item_id"], name: "index_stock_holds_on_stock_item_id"
    t.index ["stock_location_id"], name: "index_stock_holds_on_stock_location_id"
    t.check_constraint "quantity > 0", name: "stock_holds_quantity_positive"
  end

  create_table "stock_items", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.string "kind", null: false
    t.string "code", null: false
    t.integer "number"
    t.string "name", null: false
    t.string "cultivar"
    t.string "botanical_name"
    t.string "size"
    t.integer "price_cents"
    t.integer "cost_cents"
    t.string "currency", default: "ZAR", null: false
    t.text "notes"
    t.bigint "plant_id"
    t.bigint "moved_by_id"
    t.bigint "cover_photo_id"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "seller_id, lower((code)::text)", name: "index_stock_items_on_seller_and_code", unique: true
    t.index ["cover_photo_id"], name: "index_stock_items_on_cover_photo_id"
    t.index ["moved_by_id"], name: "index_stock_items_on_moved_by_id"
    t.index ["plant_id"], name: "index_stock_items_on_plant_id"
    t.index ["seller_id"], name: "index_stock_items_on_seller_id"
    t.check_constraint "cost_cents IS NULL OR cost_cents >= 0", name: "stock_items_cost_not_negative"
    t.check_constraint "price_cents IS NULL OR price_cents >= 0", name: "stock_items_price_not_negative"
  end

  create_table "stock_locations", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.string "name", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "seller_id, lower((name)::text)", name: "index_stock_locations_on_seller_and_name", unique: true
    t.index ["seller_id"], name: "index_stock_locations_on_seller_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "seller_id", null: false
    t.bigint "stock_item_id", null: false
    t.string "kind", null: false
    t.integer "quantity", null: false
    t.bigint "stock_location_id", null: false
    t.bigint "to_location_id"
    t.string "bucket", default: "saleable", null: false
    t.string "reason"
    t.bigint "stock_hold_id"
    t.bigint "member_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.index ["member_id"], name: "index_stock_movements_on_member_id"
    t.index ["seller_id"], name: "index_stock_movements_on_seller_id"
    t.index ["stock_hold_id"], name: "index_stock_movements_on_stock_hold_id"
    t.index ["stock_item_id", "occurred_at"], name: "index_stock_movements_on_stock_item_id_and_occurred_at"
    t.index ["stock_item_id"], name: "index_stock_movements_on_stock_item_id"
    t.index ["stock_location_id"], name: "index_stock_movements_on_stock_location_id"
    t.index ["to_location_id"], name: "index_stock_movements_on_to_location_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest"
    t.datetime "email_verified_at"
    t.boolean "platform_operator", default: false, null: false
    t.string "otp_secret"
    t.datetime "otp_enabled_at"
    t.datetime "otp_last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deletion_requested_at"
    t.datetime "deleted_at"
    t.datetime "whats_new_seen_at"
    t.integer "last_plant_number", default: 0, null: false
    t.string "time_zone"
    t.datetime "library_choice_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["deletion_requested_at"], name: "index_users_on_deletion_requested_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "acquisitions", "photos", column: "cover_photo_id", on_delete: :nullify
  add_foreign_key "acquisitions", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "buyer_addresses", "buyers", on_delete: :cascade
  add_foreign_key "buyer_aliases", "buyers", on_delete: :nullify
  add_foreign_key "buyer_aliases", "sellers"
  add_foreign_key "buyer_aliases", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "buyer_consents", "buyers", on_delete: :cascade
  add_foreign_key "buyer_consents", "users", column: "recorded_by_id", on_delete: :nullify
  add_foreign_key "buyer_verifications", "buyers", on_delete: :cascade
  add_foreign_key "buyer_verifications", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "buyers", "sellers"
  add_foreign_key "care_events", "care_tasks", on_delete: :nullify
  add_foreign_key "care_events", "environments", column: "from_environment_id", on_delete: :nullify
  add_foreign_key "care_events", "environments", on_delete: :nullify
  add_foreign_key "care_events", "plant_setups", on_delete: :cascade
  add_foreign_key "care_events", "plants", on_delete: :cascade
  add_foreign_key "care_events", "users"
  add_foreign_key "care_schedules", "environments"
  add_foreign_key "care_schedules", "library_profiles", on_delete: :nullify
  add_foreign_key "care_schedules", "plants"
  add_foreign_key "care_schedules", "users"
  add_foreign_key "care_tasks", "care_schedules"
  add_foreign_key "care_tasks", "environments"
  add_foreign_key "care_tasks", "plants"
  add_foreign_key "care_tasks", "users"
  add_foreign_key "consent_records", "users", on_delete: :cascade
  add_foreign_key "custom_metrics", "users"
  add_foreign_key "data_requests", "users"
  add_foreign_key "data_requests", "users", column: "handled_by_id"
  add_foreign_key "environment_assignments", "environments", on_delete: :restrict
  add_foreign_key "environment_assignments", "plants", on_delete: :cascade
  add_foreign_key "environment_assignments", "users"
  add_foreign_key "environment_event_plants", "environment_events", on_delete: :cascade
  add_foreign_key "environment_event_plants", "plants", on_delete: :cascade
  add_foreign_key "environment_events", "care_tasks", on_delete: :nullify
  add_foreign_key "environment_events", "environments"
  add_foreign_key "environment_events", "users"
  add_foreign_key "environments", "photos", column: "cover_photo_id", on_delete: :nullify
  add_foreign_key "environments", "users"
  add_foreign_key "guidance_revisions", "users"
  add_foreign_key "ingredients", "ingredients", column: "copied_from_id", on_delete: :nullify
  add_foreign_key "ingredients", "users"
  add_foreign_key "invitations", "sellers", on_delete: :cascade
  add_foreign_key "invitations", "users", column: "accepted_by_id", on_delete: :nullify
  add_foreign_key "invitations", "users", column: "invited_by_id", on_delete: :nullify
  add_foreign_key "library_dismissals", "library_profiles", on_delete: :cascade
  add_foreign_key "library_dismissals", "plants", on_delete: :cascade
  add_foreign_key "library_dismissals", "users"
  add_foreign_key "library_profile_versions", "library_profiles", on_delete: :cascade
  add_foreign_key "library_profile_versions", "users", column: "published_by_id", on_delete: :nullify
  add_foreign_key "library_profiles", "sellers"
  add_foreign_key "library_profiles", "users"
  add_foreign_key "listings", "sellers"
  add_foreign_key "listings", "stock_items"
  add_foreign_key "measurement_values", "custom_metrics", on_delete: :cascade
  add_foreign_key "measurement_values", "measurements", on_delete: :cascade
  add_foreign_key "measurements", "environments", on_delete: :cascade
  add_foreign_key "measurements", "users"
  add_foreign_key "memberships", "sellers"
  add_foreign_key "memberships", "users"
  add_foreign_key "otp_backup_codes", "users", on_delete: :cascade
  add_foreign_key "photos", "acquisitions", on_delete: :cascade
  add_foreign_key "photos", "care_events", on_delete: :cascade
  add_foreign_key "photos", "environment_events", on_delete: :cascade
  add_foreign_key "photos", "environments", on_delete: :cascade
  add_foreign_key "photos", "plants", on_delete: :cascade
  add_foreign_key "photos", "stock_items", on_delete: :cascade
  add_foreign_key "photos", "users"
  add_foreign_key "plant_setups", "plants", on_delete: :cascade
  add_foreign_key "plant_setups", "recipe_versions", on_delete: :restrict
  add_foreign_key "plant_setups", "users"
  add_foreign_key "plant_status_changes", "plants", on_delete: :cascade
  add_foreign_key "plants", "acquisitions", on_delete: :nullify
  add_foreign_key "plants", "guidance_revisions"
  add_foreign_key "plants", "library_profiles", on_delete: :nullify
  add_foreign_key "plants", "photos", column: "cover_photo_id", on_delete: :nullify
  add_foreign_key "plants", "plants", column: "split_from_id", on_delete: :nullify
  add_foreign_key "plants", "users"
  add_foreign_key "recipe_components", "ingredients", on_delete: :restrict
  add_foreign_key "recipe_components", "recipe_versions", on_delete: :cascade
  add_foreign_key "recipe_versions", "recipes", on_delete: :cascade
  add_foreign_key "recipes", "users"
  add_foreign_key "refer_visits", "refer_referral_codes", column: "referral_code_id"
  add_foreign_key "sale_cards", "listings", on_delete: :cascade
  add_foreign_key "sale_cards", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "sellers", "plans"
  add_foreign_key "sessions", "sellers", on_delete: :nullify
  add_foreign_key "sessions", "users"
  add_foreign_key "stock_balances", "stock_items", on_delete: :cascade
  add_foreign_key "stock_balances", "stock_locations"
  add_foreign_key "stock_holds", "buyer_aliases", on_delete: :nullify
  add_foreign_key "stock_holds", "buyers"
  add_foreign_key "stock_holds", "stock_items"
  add_foreign_key "stock_holds", "stock_locations"
  add_foreign_key "stock_holds", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "stock_items", "photos", column: "cover_photo_id", on_delete: :nullify
  add_foreign_key "stock_items", "plants", on_delete: :nullify
  add_foreign_key "stock_items", "sellers"
  add_foreign_key "stock_items", "users", column: "moved_by_id", on_delete: :nullify
  add_foreign_key "stock_locations", "sellers"
  add_foreign_key "stock_movements", "sellers"
  add_foreign_key "stock_movements", "stock_holds"
  add_foreign_key "stock_movements", "stock_items"
  add_foreign_key "stock_movements", "stock_locations"
  add_foreign_key "stock_movements", "stock_locations", column: "to_location_id"
  add_foreign_key "stock_movements", "users", column: "member_id", on_delete: :nullify

  create_function :protect_audit_events, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.protect_audit_events()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
        IF TG_OP = 'UPDATE' THEN
          RAISE EXCEPTION 'audit_events are append-only';
        END IF;

        IF TG_OP = 'DELETE' AND OLD.created_at > now() - interval '2 years' THEN
          RAISE EXCEPTION 'audit_events can only be deleted after 2 years';
        END IF;

        RETURN OLD;
      END;
      $function$
  SQL

  create_trigger :protect_audit_events, sql_definition: <<-SQL
      CREATE TRIGGER protect_audit_events BEFORE DELETE OR UPDATE ON public.audit_events FOR EACH ROW EXECUTE FUNCTION protect_audit_events()
  SQL
end
