module PatientsHelper
  # Pages either side of the current one that are always shown.
  PAGES_EITHER_SIDE = 1

  def patient_name(patient)
    [ patient.first_name, patient.last_name ].compact_blank.join(" ")
  end

  # Gesso renders a window it is handed and does no page maths of its
  # own, so the window is built here. Nothing to step through means no
  # controls at all.
  def patient_pagination(results)
    return if results.total_pages <= 1

    render_pagination(
      pages: patient_page_window(results),
      previous: patient_page_step(results.previous_page),
      next_page: patient_page_step(results.next_page)
    )
  end

  def patient_date_of_birth(patient)
    patient.date_of_birth&.strftime("%d/%m/%Y")
  end

  # iPM describes gender in words; the patient info header appends a
  # single letter after the name, and shows nothing for anything else.
  def patient_gender_code(patient)
    patient.gender.to_s.first&.upcase
  end

  private
    # The ends, the current page and its neighbours, with an ellipsis
    # standing in for whatever the jumps skip over.
    def patient_page_window(results)
      window = []
      previous = nil

      patient_page_numbers(results).each do |number|
        window << :gap if previous && number > previous + 1
        window << {
          number: number, path: patient_page_path(number),
          current: number == results.current_page
        }
        previous = number
      end

      window
    end

    def patient_page_numbers(results)
      current = results.current_page
      neighbours = (current - PAGES_EITHER_SIDE)..(current + PAGES_EITHER_SIDE)

      [ 1, *neighbours, results.total_pages ]
        .select { |number| number.between?(1, results.total_pages) }
        .uniq.sort
    end

    def patient_page_step(number)
      { path: patient_page_path(number) } if number
    end

    # The criteria are already in the query string, so a page link is
    # this search with a different page on it.
    def patient_page_path(number)
      patients_search_path(
        request.query_parameters.except("page").merge(page: number)
      )
    end
end
