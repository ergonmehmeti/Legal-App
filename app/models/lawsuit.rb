class Lawsuit < ApplicationRecord

  has_many :comments, dependent: :destroy
  accepts_nested_attributes_for :comments, reject_if: proc { |attributes| attributes['id'].present? }
  has_many_attached :pdf_files, dependent: :destroy


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

  enum court: {
    themelore: "Gjykata Themelore",
    komerciale: "Gjykata Komerciale",
    apelit: "Gjykata Apelit",
    supreme: "Gjykata Supreme",
    kushtetuese: "Gjykata Kushtetuese"
  }

  attribute :status, :string, default: "Ne pritje"
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :category, presence: true, inclusion: { in: categories.keys }
  validates :court, presence: true, inclusion: { in: courts.keys }



  # description = Pershkrimi i Lendes
  # context_type = Natyra e Kontekstit
  # plaintiff = Paditesi

  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }
  def category_value
    self.class.categories[category]
  end

  def status_value
    self.class.statuses[status]
  end

  def court_value
    self.class.courts[court]
  end

  def self.important_lawsuits(category)
    where(category: category, status: [:active, :pending]).order(created_at: :desc)
  end

  def self.filter_by_params(category, params)
    # Start with all records
    results = where(category: category)
    if params[:status].present?
      results = results.where(status: params[:status]) if params[:status].present?
    else
      results = results.where(status: %w[active pending])
    end
    # Apply filters conditionally
    results = results.where('plaintiff LIKE ?', "%#{params[:plaintiff]}%") if params[:plaintiff].present?
    results = results.where('lawsuit_number LIKE ?', "%#{params[:lawsuit_number]}%") if params[:lawsuit_number].present?
    results
  end

end
