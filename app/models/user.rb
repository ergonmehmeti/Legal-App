class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :comments

  validates :name, :surname, :kt_id, presence: true
  validates :kt_id, numericality: { only_integer: true, greater_than: 0 }

  enum role: { admin_developer: 0, admin: 1, operator: 2 }

end
