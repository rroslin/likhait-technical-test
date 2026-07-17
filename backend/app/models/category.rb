class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  before_validation :strip_name

  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: true

  private

  def strip_name
    self.name = name.strip if name.present?
  end
end
