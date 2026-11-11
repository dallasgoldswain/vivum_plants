# Plants live in a personal collection (D87): only their owner sees or changes them,
# whatever seller they are acting for.
class PlantPolicy < ApplicationPolicy
  def index? = user.present?
  def create? = user.present?
  def show? = owner?
  def update? = owner?
  def destroy? = owner?

  relation_scope { |relation| user ? relation.where(user_id: user.id) : relation.none }

  private
    def owner?
      user.present? && record.user_id == user.id
    end
end
