class Lawsuit < ApplicationRecord

  has_many :comments, dependent: :destroy
  accepts_nested_attributes_for :comments, reject_if: proc { |attributes| attributes['id'].present? }
  has_many_attached :pdf_files, dependent: :destroy
  has_many :provisions, dependent: :destroy
  accepts_nested_attributes_for :provisions #, reject_if: proc { |attributes| attributes['id'].present? }




  enum category: {
    kontestet_punes: "Kontestet e Punës",
    kontestet_palet_treta_tk_padites: "Kontestet me Palë të Treta - TK Paditës",
    kontestet_palet_treta_tk_paditur: "Kontestet me Palë të Treta - TK e Paditur",
    lendet_penale: "Lëndët Penale",
    lendet_administrative_inspektoriat: "Lëndët Administrative në Inspektoriat",
    lendet_administrative: "Lëndët Administrative në Gjykatë",
    lendet_arbitrazhit: "Lëndët në Arbitrazh",
    lendet_permbarimore_kreditore: "Lëndët Përmbarimore TK Kreditor",
    lendet_permbarimore_debitore: "Lëndët Përmbarimore TK Debitor"
  }
  enum status: {
    pending: "Në Pritje",
    active: "Aktive",
    suspended: "Pezulluar",
    finished: "Përfunduar"
  }
  enum court: {
    themelore: "Gjykata Themelore",
    themelore_2: "Gjykata Themelore Rigjykim 2",
    komerciale: "Gjykata Komerciale Dh.Sh.1",
    komerciale_2: "Gjykata Komerciale Dh.SH.2",
    komerciale_rigjykim: "Gjykata Komerciale Dh.Sh.1 Rigjykim",
    komerciale_2_rigjykim: "Gjykata Komerciale Dh.SH.2 Rigjykim",
    apelit: "Gjykata e Apelit",
    apelit_2: "Gjykata e Apelit 2",
    supreme: "Gjykata Supreme",
    supreme_2: "Gjykata Supreme 2",
    kushtetuese: "Gjykata Kushtetuese"
  }
  enum lawsuit_risk: {
    ulet: "Ulët",
    mesme: "Mesëm",
    larte: "Lartë",
    pa_caktuar: "Pa Caktuar"
  }
  enum lawsuit_state: {
    ngritur_aktakuze: "Është ngritur Aktakuzë",
    faze_hetimesh: "Është në fazën e hetimeve",
    ska_informacion: "Ska informacion",
    perfunduar_aktgjykim: "E përfunduar me Aktgjykim",
    hedhur_kallezimi_penal: "Është hedhur poshtë kallëzimi penal",
    procedure_permbarimore: "Në procedurë përmbarimorë",
    ekzekutuar_pp: "Është ekzekutuar nga PP",
    padi_konflikt_administrativ: "Është ngritur padi për Konflikt Administrative",
    anuluar_vendimi_inspektoratit: "Është anuluar vendimi i Inspektoratit nga Gjykata",
    vertetuar_vendimi_inspektoratit: "Është vërtetuar vendimi i Inspektoratit"
  }
  enum civil_lawsuit: {
    positive: "PO",
    negative: "JO"
  }
  enum lawsuit_phase_procedure: {
    prokurori: "Prokurori",
    gjykate: "Gjykatë",
    permbarues: "Përmbarues Privat",
    raport_zyrtar: "Raport Zyrtar",
    raport_me_verejtje: "Është Paraqitur Vërejtje në Raport",
    ankese: "Është paraqitur Ankesë",
    shkalla_pare_inspektoriat: "Vendimi i shkallës së parë të Inspektoratit",
    shkalla_dyte_inspektoriat: "Vendimi i shkallës së dytë të Inspektoratit",
    inspektoriat_rigjykim_pare: "Vendimi i shkallës së parë të Inspektoratit Rigjykim",
    inspektoriat_rigjykim_dyte: "Vendimi i shkallës së dytë të Inspektoratit Rrigjykim"
  }
  attribute :status, :string, default: "Në Pritje"

  before_validation :reject_empty_provisions

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :category, presence: true, inclusion: { in: categories.keys }
  validates :lawsuit_state, presence: true, if: :requires_lawsuit_state?
  validates :lawsuit_phase_procedure, presence: true, if: :requires_lawsuit_phase_procedure?

  validates :lawsuit_amount_claim, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :provision, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true



  # title = Numri TK
  # category = Kategoria
  # description = Pershkrimi i Lendes
  # context_type = Natyra e Kontestit
  # plaintiff = Paditesi - Paraqitesi i Kallezimit - Debitori - Kreditori
  # lawsuit_claim = "I Pandehuri"
  # lawsuit_number = Numri i Lendes
  # court = Gjykata
  # lawsuit_amount_claim = Shuma e Kerkesepadise
  # provision = Provizionimi
  # lawsuit_risk = Rreziku
  # lawsuit_state = Gjendja e Lendes
  # status = Statusi
  # civil_lawsuit = Padi Civile
  # lawsuit_phase_procedure = Faza e procedures, Faza e Kallzimit Penal, Zhvillimi i Procedures
  # institution = Institucioni
  # lawsuit_development_procedure = "E shtuar kot, sa me qene aty"

  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }

  def category_value
    self.class.categories[category]
  end

  def enum_value(attribute)
    self.class.public_send(attribute.to_s.pluralize)[public_send(attribute)]
  end

  def requires_lawsuit_state?
    %w[lendet_penale lendet_administrative_inspektoriat lendet_administrative].include?(category)
  end
  def requires_lawsuit_phase_procedure?
    %w[lendet_penale lendet_administrative_inspektoriat lendet_administrative lendet_permbarimore_kreditore lendet_permbarimore_debitore ].include?(category)
  end
  def lawsuit_state_options_for_select
    if category == "lendet_penale"
      {
        ngritur_aktakuze: "Është ngritur Aktakuzë",
        faze_hetimesh: "Është në fazën e hetimeve",
        ska_informacion: "Ska informacion",
        perfunduar_aktgjykim: "E përfunduar me Aktgjykim",
        hedhur_kallezimi_penal: "Është hedhur poshtë kallëzimi penal"
      }
    elsif category == "lendet_administrative_inspektoriat" || category == "lendet_administrative"
      {
        procedure_permbarimore: "Në procedurë përmbarimorë",
        ekzekutuar_pp: "Është ekzekutuar nga PP",
        padi_konflikt_administrativ: "Është ngritur padi për Konflikt Administrative",
        anuluar_vendimi_inspektoratit: "Është anuluar vendimi i Inspektoratit nga Gjykata",
        vertetuar_vendimi_inspektoratit: "Është vërtetuar vendimi i Inspektoratit"
        }
    else
      {}
    end
  end
  def lawsuit_phase_procedure_options_for_select
    if category == "lendet_penale"
      {
        prokurori: "Prokurori",
        gjykate: "Gjykatë"
      }
    elsif category == "lendet_administrative_inspektoriat" || category == "lendet_administrative"
      {
        raport_zyrtar: "Raport Zyrtar",
        raport_me_verejtje: "Është Paraqitur Vërejtje në Raport",
        ankese: "Është paraqitur Ankesë",
        shkalla_pare_inspektoriat: "Vendimi i shkallës së parë të Inspektoratit",
        shkalla_dyte_inspektoriat: "Vendimi i shkallës së dytë të Inspektoratit",
        inspektoriat_rigjykim_pare: "Vendimi i shkallës së parë të Inspektoratit Rigjykim",
        inspektoriat_rigjykim_dyte: "Vendimi i shkallës së dytë të Inspektoratit Rrigjykim"

      }
    elsif category == "lendet_permbarimore_debitore" || category == "lendet_permbarimore_kreditore"
      {
        gjykate: "Gjykatë",
        permbarues: "Përmbarues Privat"
      }
    else
      {}
    end
  end

  def reject_empty_provisions
    # Only keep services where at least one of provision_value or provision_year is not blank
    self.provisions = provisions.select { |provision| provision.provision_value.present? && provision.provision_year.present? }
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
