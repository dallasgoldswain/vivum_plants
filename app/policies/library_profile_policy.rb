# Published platform profiles are readable and copyable by every collector; a collector's own
# profiles belong to them only (D149, D150).
class LibraryProfilePolicy < ApplicationPolicy
  def index? = user.present?
  def create? = user.present?
  def show? = user.present? && (owner? || published_platform?)
  def copy? = user.present? && published_platform?
  def update? = owner?
  def destroy? = owner?

  alias_rule :edit?, to: :update?

  relation_scope { |relation| user ? relation.where(user_id: user.id) : relation.none }

  private
    def owner? = user.present? && record.user_id == user.id
    def published_platform? = record.platform? && record.published_version.present?
end
