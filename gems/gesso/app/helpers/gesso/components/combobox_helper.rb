module Gesso::Components
  module ComboboxHelper
    # Renders the combobox component — a searchable select. This is the
    # public entry point: it normalises the selected value and resolves
    # the label to show on the trigger, so the partial stays pure markup.
    #
    #   render_combobox(name: "clinician", selected: id, options: [...])
    def render_combobox(name: nil, options: [], selected: nil,
                        placeholder: "Select…", searchable: true, id: nil)
      selected = selected.to_s
      current = options.find { |option| option[:value].to_s == selected }

      render("gesso/components/combobox",
        name:, options:, selected:,
        current_label: current ? current[:label] : placeholder,
        searchable:, id:)
    end
  end
end
