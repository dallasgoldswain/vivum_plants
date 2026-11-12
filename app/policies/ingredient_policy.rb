# Built-in ingredients are readable by every collector and edited by nobody (D96); personal
# ingredients belong to their owner only (D87).
class IngredientPolicy < ApplicationPolicy
  def index? = user.present?
  def create? = user.present?
  def show? = user.present? && (record.built_in? || owner?)
  def copy? = show?
  def update? = owner?
  def destroy? = owner?

  alias_rule :edit?, to: :update?

  relation_scope { |relation| user ? relation.visible_to(user) : relation.none }

  private
    def owner?
      user.present? && record.user_id == user.id
    end
end
