class User < ApplicationRecord
  has_paper_trail
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :comments
  has_many :deleted_lawsuits, class_name: 'Lawsuit', foreign_key: 'deleted_by_user_id'
  # Assignments as legal representative (a user who is assigned somewhere can't be deleted).
  # Their lawsuits: Lawsuit.represented_by(user)
  has_many :lawsuit_representatives, dependent: :restrict_with_error

  validates :name, :surname, :kt_id, presence: true
  # kt_id = Kosovo Telecom employee ID
  validates :kt_id, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true

  # On create Devise allows min 6 (admin can set e.g. 123456);
  # every password change after that needs at least 8 characters.
  validates :password, length: { minimum: 8 }, allow_nil: true, on: :update

  # category_scopes: categories (keys of Lawsuit.categories) in which a legal representative sees
  # ALL lawsuits, read only, besides the ones they are assigned to (LawsuitPolicy::Scope).
  # Only for the legal_representative role; cleared for every other role.
  before_validation :clean_category_scopes
  validate :category_scopes_must_exist

  # validate: true -> role is required and must be one of these (no "no role" users)
  # legal_representative = "Përfaqësues Ligjor": view-only, sees only the lawsuits
  # they are assigned to (see TODO_LAWYER.md)
  enum :role, { admin_developer: 0, admin: 1, operator: 2, legal_representative: 3 }, validate: true

  # Names shown in the app (role keys stay English in the code / database)
  ROLE_LABELS = {
    "admin_developer" => "Admin Developer",
    "admin" => "Admin",
    "operator" => "Operator",
    "legal_representative" => "Përfaqësues Ligjor"
  }.freeze

  # Deactivation: users are never deleted (comments / audit history stay linked)
  scope :active_users, -> { where(active: true) }
  scope :inactive_users, -> { where(active: false) }
  # Choices for "Përfaqësuesi" in the lawsuit form: active users of every role except admin_developer
  scope :assignable_representatives, -> { active_users.where.not(role: :admin_developer).order(:name, :surname) }

  def self.role_label(role)
    ROLE_LABELS.fetch(role.to_s, role.to_s.titleize)
  end

  def role_label
    self.class.role_label(role)
  end

  # Devise checks this on login AND on every request,
  # so a deactivated user is logged out on their next click.
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :deactivated
  end

  private

  def clean_category_scopes
    self.category_scopes = legal_representative? ? Array(category_scopes).compact_blank.map(&:to_s).uniq : []
  end

  def category_scopes_must_exist
    unknown = category_scopes - Lawsuit.categories.keys
    errors.add(:category_scopes, "ka kategori të panjohura: #{unknown.join(', ')}") if unknown.any?
  end
end
