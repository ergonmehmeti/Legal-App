class Lawsuit < ApplicationRecord
  include Discard::Model
  has_paper_trail

  has_many :comments, dependent: :destroy
  accepts_nested_attributes_for :comments, reject_if: proc { |attributes| attributes['id'].present? }
  
  # Keep PDF files for archival - don't auto-destroy
  has_many_attached :pdf_files
  # "Deleted" PDFs: hidden from everyone except admin_developer, file stays on disk
  has_many_attached :deleted_pdf_files
  has_many :pdf_file_deletions, dependent: :destroy

  has_many :provisions, dependent: :destroy
  accepts_nested_attributes_for :provisions #, reject_if: proc { |attributes| attributes['id'].present? }
  
  belongs_to :deleted_by_user, class_name: 'User', optional: true

  # Legal representatives ("Përfaqësues Ligjor"): one primary + optional secondary ones
  has_many :lawsuit_representatives, dependent: :destroy
  has_many :representatives, through: :lawsuit_representatives, source: :user
  # THE rule "lawsuits this user represents" (primary or secondary). Used by LawsuitPolicy::Scope,
  # Kryefaqja and "Lëndët e Mia": change it only here. Subquery (not a join): no duplicate rows.
  scope :represented_by, ->(user) { where(id: LawsuitRepresentative.where(user_id: user.id).select(:lawsuit_id)) }

  # Validations: Prevent duplicate title + lawsuit_number combination among active lawsuits
  # Lawsuit_number alone can repeat (same case number in different categories)
  # Title alone can repeat (different cases with same title)
  # But the COMBINATION of title + lawsuit_number must be unique
  validates :title, presence: true, uniqueness: { 
    scope: :lawsuit_number,
    conditions: -> { kept },  # Only check among non-deleted lawsuits
    message: "and lawsuit number combination already exists for an active lawsuit"
  }

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
  # court = the court's NAME as text (e.g. "Gjykata Themelore"). The list of courts is the
  # `courts` table, managed by admin_developer in the Admin area (see Court, TODO_COURTS.md).
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

  # "Statusi Final i Lëndës" (all categories, optional). The key is stored, the label is shown,
  # so a label can be corrected later without touching the data.
  FINAL_STATUSES = {
    "aprovohet" => "Aprovohet Padia",
    "aprovohet_pjeserisht" => "Aprovohet pjesërisht Padia",
    "refuzohet" => "Refuzohet Padia"
  }.freeze
  before_validation { self.final_status = final_status.presence }
  validates :final_status, inclusion: { in: FINAL_STATUSES.keys }, allow_nil: true
  # Empty court in the form = no court (nil, not "")
  before_validation { self.court = court.presence }
  # A newly chosen court must be an active one. An old value (e.g. a court deactivated later)
  # stays valid as long as it isn't changed.
  validate :court_must_be_active, if: -> { court.present? && will_save_change_to_court? }



  # title = Numri TK
  # category = Kategoria
  # description = Pershkrimi i Lendes
  # context_type = Natyra e Kontestit
  # plaintiff = Paditesi - Paraqitesi i Kallezimit - Debitori (TK Kreditor) - Kreditori (TK Debitor)
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

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }

  def category_value
    self.class.categories[category]
  end

  def final_status_label
    FINAL_STATUSES[final_status]
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

  def primary_representative
    lawsuit_representatives.find(&:is_primary)&.user
  end

  def secondary_representatives
    lawsuit_representatives.reject(&:is_primary).map(&:user)
  end

  # Replace all representatives of this lawsuit in one go (from the lawsuit form).
  # primary_id: one user id or blank; secondary_ids: list of user ids (may be empty).
  # The primary is never also stored as secondary. Unchanged rows are kept, so
  # PaperTrail only records real changes.
  def assign_representatives!(primary_id:, secondary_ids: [])
    primary_id = primary_id.presence&.to_i
    secondary_ids = Array(secondary_ids).compact_blank.map(&:to_i).uniq - [primary_id]
    wanted = secondary_ids.index_with(false)
    wanted[primary_id] = true if primary_id

    # requires_new: if one assignment is invalid, everything in here is undone,
    # even when this runs inside another transaction
    transaction(requires_new: true) do
      current = lawsuit_representatives.to_a
      current.each do |rep|
        if !wanted.key?(rep.user_id)
          rep.destroy!
        elsif rep.is_primary && !wanted[rep.user_id]
          rep.update!(is_primary: false) # was primary, now secondary: free the slot first
        end
      end
      wanted.each do |user_id, is_primary|
        rep = current.find { |r| r.user_id == user_id && !r.destroyed? } ||
              lawsuit_representatives.build(user_id: user_id)
        rep.is_primary = is_primary
        rep.save! if rep.new_record? || rep.changed?
      end
    end
    lawsuit_representatives.reset
  end

  # Who was representative of this lawsuit and when, rebuilt from the PaperTrail history of
  # LawsuitRepresentative (no extra table). One entry per period with the same role:
  #   { user:, is_primary:, from:, to: (nil = still current), added_by:, removed_by: }
  # A switch primary <-> secondary closes one period and opens the next.
  # Only admins see this (LawsuitPolicy#view_representative_history?). Newest first.
  def representative_history
    rep_type = LawsuitRepresentative.name
    live = lawsuit_representatives.to_a
    # Removed rows only exist in their "destroy" version (object = the row as it was)
    # Text search first (no JSON cast in SQL: an old history row in another format can't break the
    # page), then a real check of each candidate in Ruby ("lawsuit_id":3 also matches 30, 31, ...)
    removed_ids = PaperTrail::Version.where(item_type: rep_type, event: "destroy")
                                     .where("object LIKE ?", %(%"lawsuit_id":#{id.to_i}%))
                                     .select { |v| (v.object_deserialized rescue nil)&.dig("lawsuit_id") == id }
                                     .map(&:item_id)
    versions = PaperTrail::Version.where(item_type: rep_type, item_id: live.map(&:id) + removed_ids)
                                  .order(:created_at, :id).group_by(&:item_id)

    rows = versions.keys.union(live.map(&:id)).map do |item_id|
      item_versions = versions.fetch(item_id, [])
      live_rep = live.find { |r| r.id == item_id }
      created = item_versions.find { |v| v.event == "create" }
      destroyed = item_versions.find { |v| v.event == "destroy" }
      # "update"/"destroy" versions hold the row as it was BEFORE that change
      states = item_versions.reject { |v| v.event == "create" }.map { |v| v.object_deserialized || {} }
      final = live_rep ? live_rep.attributes : states.last
      next [] unless final

      start_at = created&.created_at || Time.zone.parse(final["created_at"].to_s)
      start_by = created&.whodunnit
      is_primary = (states.first || final)["is_primary"]
      periods = []
      item_versions.select { |v| v.event == "update" }.each_with_index do |v, i|
        next_primary = (states[i + 1] || final)["is_primary"]
        next if next_primary == is_primary # nothing changed in the role
        periods << { user_id: final["user_id"], is_primary: is_primary, from: start_at, to: v.created_at,
                     added_by: start_by, removed_by: v.whodunnit }
        start_at, start_by, is_primary = v.created_at, v.whodunnit, next_primary
      end
      periods << { user_id: final["user_id"], is_primary: is_primary, from: start_at,
                   to: destroyed&.created_at, added_by: start_by, removed_by: destroyed&.whodunnit }
    end.flatten

    users = User.where(id: rows.flat_map { |r| [r[:user_id], r[:added_by], r[:removed_by]] }.compact).index_by(&:id)
    rows.map do |r|
      r.merge(user: users[r[:user_id].to_i],
              added_by: r[:added_by] && users[r[:added_by].to_i],
              removed_by: r[:removed_by] && users[r[:removed_by].to_i])
    end.sort_by { |r| [r[:from], r[:to] ? 0 : 1] }.reverse
  end

  # Hide a PDF: move it from pdf_files to deleted_pdf_files and record who/why.
  def hide_pdf!(attachment, user:, reason:)
    transaction do
      pdf_file_deletions.create!(attachment: attachment, deleted_by_user: user, reason: reason)
      attachment.update!(name: "deleted_pdf_files")
    end
  end

  # Restore a hidden PDF back to pdf_files (PaperTrail keeps the deletion history).
  def restore_pdf!(attachment)
    transaction do
      pdf_file_deletions.find_by(attachment: attachment)&.destroy!
      attachment.update!(name: "pdf_files")
    end
  end

  def reject_empty_provisions
    # Only keep services where at least one of provision_value or provision_year is not blank
    self.provisions = provisions.select { |provision| provision.provision_value.present? && provision.provision_year.present? }
  end

  def self.important_lawsuits(category)
    lawsuits = kept.where(category: category, status: [:active, :pending])
    
    # Sort numeric titles numerically, non-numeric titles at the end alphabetically
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      lawsuits.order(Arel.sql("CASE WHEN title ~ '^[0-9]+$' THEN CAST(title AS INTEGER) ELSE 999999 END ASC, title ASC"))
    else
      # SQLite: safer approach - sort by length first (assumes numeric), then by value
      lawsuits.order(Arel.sql("LENGTH(title) ASC, title ASC"))
    end
  end
  def self.filter_by_params(category, params)
    # Start with kept (non-deleted) records
    results = kept.where(category: category)
    if params[:status].present?
      results = results.where(status: params[:status]) if params[:status].present?
    else
      results = results.where(status: %w[active pending])
    end
    # Apply filters conditionally
    results = results.where('plaintiff ILIKE ?', "%#{params[:plaintiff]}%") if params[:plaintiff].present?
    results = results.where('lawsuit_number ILIKE ?', "%#{params[:lawsuit_number]}%") if params[:lawsuit_number].present?
    # "Numri TK" = the title column
    results = results.where('title ILIKE ?', "%#{params[:tk_number]}%") if params[:tk_number].present?
    
    # Sort numeric titles numerically, non-numeric titles at the end alphabetically
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      results.order(Arel.sql("CASE WHEN title ~ '^[0-9]+$' THEN CAST(title AS INTEGER) ELSE 999999 END ASC, title ASC"))
    else
      # SQLite: safer approach - sort by length first (assumes numeric), then by value
      results.order(Arel.sql("LENGTH(title) ASC, title ASC"))
    end
  end


  private

  def court_must_be_active
    errors.add(:court, "nuk është në listën e gjykatave aktive") unless Court.active.exists?(name: court)
  end
end
