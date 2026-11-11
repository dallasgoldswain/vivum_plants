require "test_helper"

class AccountExportTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def entries(user)
    Zip::InputStream.open(StringIO.new(AccountExport.new(user).to_zip)) do |zip|
      {}.tap { |files| while (entry = zip.get_next_entry) do files[entry.name] = zip.read end }
    end
  end

  test "the zip has a manifest, a readme and every section, with only this user's data" do
    files = entries(users(:manager))

    assert_equal [ "README.txt", "manifest.json", *AccountExport::SECTIONS.keys.map { "#{it}.json" } ].sort, files.keys.sort
    assert_equal "manager@example.com", JSON.parse(files["account.json"])["email_address"]
    assert_equal [ "Aroid Attic", "Fern & Frond" ], JSON.parse(files["memberships.json"]).map { it["seller"] }.sort
    assert_no_match "owner@example.com", files.values.join
  end

  test "the job attaches the file, closes the request and emails a link" do
    request = users(:collector).data_requests.create!(kind: "export")

    assert_enqueued_email_with PrivacyMailer, :export_ready, args: [ request ] do
      ExportAccountJob.perform_now(request)
    end

    request.reload
    assert request.completed?
    assert request.downloadable?
  end

  test "only one export at a time" do
    users(:collector).data_requests.create!(kind: "export")

    assert_not users(:collector).data_requests.create(kind: "export").persisted?
  end

  test "exports expire after 7 days" do
    request = users(:collector).data_requests.create!(kind: "export")
    ExportAccountJob.perform_now(request)
    travel 8.days

    DataRequest.expire_exports!
    assert_not request.reload.export_file.attached?
    assert_not request.downloadable?
  end
end
