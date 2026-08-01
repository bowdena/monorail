module Gesso::Components
  module ComboboxHelper
    # Renders the combobox component — a searchable select. This is the
    # public entry point: it normalises the selected value and resolves
    # the id basecoat needs to tie the input to its listbox, so the
    # partial stays pure markup.
    #
    #   render_combobox(name: "clinician", selected: id, options: [...])
    #
    # A short list that needs no filtering is a native select, written
    # inline — see the form fields guidance.
    def render_combobox(name: nil, options: [], selected: nil,
                        placeholder: "Select…", id: nil)
      render("gesso/components/combobox",
        id: id || combobox_id(name),
        name:, options:, selected: selected.to_s, placeholder:)
    end

    private
      # basecoat derives the popover and listbox ids from the root's, so
      # the root needs one whether or not the caller supplied it.
      def combobox_id(name)
        name.present? ? "combobox-#{name}" : "combobox-#{SecureRandom.hex(4)}"
      end
  end
end
