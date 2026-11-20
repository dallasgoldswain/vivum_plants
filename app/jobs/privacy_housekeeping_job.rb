# Daily privacy retention (PR07, D68–D70): purges accounts past their 30-day deletion grace
# period, removes export files older than 7 days, and drops consent records of accounts
# deleted longer ago than the audit retention period. Buyer addresses unused for 12 months
# are redacted (D188).
class PrivacyHousekeepingJob < ApplicationJob
  queue_as :default

  def perform
    User.purge_due!
    DataRequest.expire_exports!
    User.purge_expired_consent_records!
    BuyerAddress.redact_unused!
  end
end
