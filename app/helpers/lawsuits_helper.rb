module LawsuitsHelper
  def render_page_title(category)
    Lawsuit.categories[category]
  end
end
