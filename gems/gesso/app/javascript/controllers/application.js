// The one Stimulus application for a page using gesso. Host apps reach it
// as "gesso/application" and register their own controllers on it, rather
// than calling Application.start() a second time — two applications both
// observe the whole document and fight over window.Stimulus.
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
