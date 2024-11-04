class Lawsuit < ApplicationRecord

  enum category: {
    lendet_civile: "Lendet Civile",
    lendet_penale: "Lendet Penale",
    lendet_administrative: "Lendet Administrative"
  }
  enum status: {
    active: "Aktive",
    pending: "Ne pritje",
    suspended: "Pezulluar",
    finished: "Perfunduar"
  }

  attribute :status, :string, default: "Ne pritje"


  # description = pershkrimi i lendes
  # context_type = natyra e kontekstit

  def category_value
    self.class.categories[category]
  end
end
