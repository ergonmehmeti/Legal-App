class User < ApplicationRecord
  has_paper_trail
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :comments
  has_many :deleted_lawsuits, class_name: 'Lawsuit', foreign_key: 'deleted_by_user_id'

  validates :name, :surname, :kt_id, presence: true
  # kt_id = Kosovo Telecom employee ID
  validates :kt_id, numericality: { only_integer: true, greater_than: 0 }, uniqueness: true

  # On create Devise allows min 6 (admin can set e.g. 123456);
  # every password change after that needs at least 8 characters.
  validates :password, length: { minimum: 8 }, allow_nil: true, on: :update

  # validate: true -> role is required and must be one of these (no "no role" users)
  enum :role, { admin_developer: 0, admin: 1, operator: 2 }, validate: true

end
