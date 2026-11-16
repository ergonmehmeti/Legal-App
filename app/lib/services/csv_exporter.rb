require "csv"
module Services
  class CsvExporter
    def initialize(lawsuits, selected_year)
      @lawsuits = lawsuits
      @selected_year = selected_year.to_i
      @previous_year = @selected_year - 1
    end

    def generate_csv
      headers = [ "Nr.", "Paditesi", "Nr Arkives TK", "Numri i Lendes", "Kategoria", "Gjykata", "Statusi",
                  "Shuma e Kerkeses", "Provizionimi #{@previous_year}", "Provizionimi #{@selected_year}" ]
      CSV.generate(headers: true) do |csv|
        csv << headers
        index = 0

        @lawsuits.each do |lawsuit|

          provision_previous_value = 0
          provision_selected_value = 0
          # Check if the lawsuit has provisions
          if lawsuit.provisions.any?
            lawsuit.provisions.each  do |provision|
              if provision.provision_year == @previous_year
                provision_previous_value = provision.provision_value
              elsif provision.provision_year == @selected_year
                provision_selected_value = provision.provision_value
              end
            end
            index += 1
            csv << [
              index,
              lawsuit.plaintiff,
              lawsuit.title,
              lawsuit.lawsuit_number,
              category_label(lawsuit),
              lawsuit.court,
              status_label(lawsuit),
              lawsuit.lawsuit_amount_claim,
              provision_previous_value,
              provision_selected_value
            ]
          else
            index += 1
            csv << [
              index,
              lawsuit.plaintiff,
              lawsuit.title,
              lawsuit.lawsuit_number,
              category_label(lawsuit),
              lawsuit.court,
              status_label(lawsuit),
              lawsuit.lawsuit_amount_claim,
              provision_previous_value,
              provision_selected_value
            ]
          end
        end
      end
    end

    private

    # Readable names instead of codes ("Kontestet e Punës", not "kontestet_punes")
    def category_label(lawsuit)
      Lawsuit.categories[lawsuit.category] || lawsuit.category
    end

    # "Aktive", not "active"
    def status_label(lawsuit)
      lawsuit.status.present? ? lawsuit.enum_value(:status) : nil
    end
  end
end
