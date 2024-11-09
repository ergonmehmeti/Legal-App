class Lawsuit < ApplicationRecord

  enum category: {
    kontestet_punes: "Kontestet e Punes",
    kontestet_palet_treta: "Kontestet me Pale te Treta",
    lendet_penale: "Lendet Penale",
    lendet_administrative: "Lendet Administrative",
    lendet_civile_tk: "Lendet Civile Tk Padites",
    lendet_arbitrazhit: "Lendet Ne Arbitrazhit",
    lendet_permbarimore_kreditore: "Lendet Permbarimore TK Kreditor",
    lendet_permbarimore_debitore: "Lendet Permbarimore TK Debitor"
  }
  enum status: {
    pending: "Ne Pritje",
    active: "Aktive",
    suspended: "Pezulluar",
    finished: "Perfunduar"
  }

  attribute :status, :string, default: "Ne pritje"
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :category, presence: true, inclusion: { in: categories.keys }



  # description = Pershkrimi i Lendes
  # context_type = Natyra e Kontekstit
  # plaintiff = Paditesi


  def category_value
    self.class.categories[category]
  end

  def status_value
    self.class.statuses[status]
  end
end
