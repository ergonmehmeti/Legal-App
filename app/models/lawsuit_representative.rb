# A legal representative ("Përfaqësues Ligjor") assigned to a lawsuit.
# PaperTrail keeps who assigned / removed whom and when.
class LawsuitRepresentative < ApplicationRecord
  has_paper_trail

  belongs_to :lawsuit
  belongs_to :user

  validates :user_id, uniqueness: { scope: :lawsuit_id }
  validate :user_must_be_assignable

  private

  # Anyone except admin_developer (the technical account) can be a lawsuit's representative.
  # Being assigned only changes access for the legal_representative role (they see only
  # assigned lawsuits); admins and operators keep seeing everything as before.
  def user_must_be_assignable
    return if user.nil? || !user.admin_developer?

    errors.add(:user, "Admin Developer nuk mund të jetë përfaqësues i lëndës")
  end
end
