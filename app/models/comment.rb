class Comment < ApplicationRecord
  validates :content, presence: true
  belongs_to :lawsuit
  belongs_to :user
end
