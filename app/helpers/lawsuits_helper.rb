module LawsuitsHelper
  def render_page_title(category)
    Lawsuit.categories[category]
  end

  # Name of the "plaintiff" column / filter, it depends on the category.
  # nil = several categories mixed ("Lëndët e Mia" with "Të gjitha"): neutral "Pala".
  def plaintiff_label(category)
    case category
    when nil then "Pala"
    # "TK Kreditor" = Telekomi is the creditor, so the other party is the Debitori (and vice versa)
    when "lendet_permbarimore_kreditore" then "Debitori"
    when "lendet_permbarimore_debitore" then "Kreditori"
    when "lendet_penale" then "Paraqitësi i Kallëzimit / I Dëmtuari"
    else "Paditësi"
    end
  end
end
