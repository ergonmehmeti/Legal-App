# A court ("Gjykata"), managed by admin_developer in the Admin area (see TODO_COURTS.md).
# Lawsuits store the court's NAME as text in lawsuits.court (no court_id), so:
# - deactivating only hides it from the dropdown, lawsuits keep showing the name
# - renaming also renames it in the lawsuits that use it (same transaction)
# Courts are never deleted. PaperTrail keeps who added / renamed / deactivated and when.
class Court < ApplicationRecord
  has_paper_trail

  before_validation { self.name = name.to_s.squish }

  validates :name, presence: { message: "nuk mund të jetë bosh" },
                   length: { maximum: 150, message: "është shumë i gjatë (max. 150 karaktere)" },
                   uniqueness: { case_sensitive: false, message: "ekziston tashmë" }
  validates :position, numericality: { only_integer: true, message: "duhet të jetë numër i plotë" }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  after_update :rename_in_lawsuits, if: :saved_change_to_name?

  # Courts are only deactivated, never deleted
  before_destroy { throw :abort }

  # Lawsuits (also archived ones) that use this court. Capitals are ignored, so a lawsuit
  # with "gjykata themelore" belongs to "Gjykata Themelore" too.
  def self.lawsuits_named(court_name)
    Lawsuit.with_discarded.where("LOWER(court) = LOWER(?)", court_name.to_s)
  end

  # How many lawsuits use this court (name as stored in the database, also while editing)
  def lawsuits_count
    self.class.lawsuits_named(name_in_database).count
  end

  private

  # Also turns spelling variants with other capitals into the new name
  def rename_in_lawsuits
    self.class.lawsuits_named(name_before_last_save).update_all(court: name)
  end
end
