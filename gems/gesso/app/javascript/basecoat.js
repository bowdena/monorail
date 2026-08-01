// Basecoat's component behaviour (dropdowns, selects, tabs, toasts, …)
// bundled from the basecoat-css npm package, so there is one source of
// basecoat instead of a vendored copy. The import sets the
// window.basecoat global, so consuming apps keep the full API
// (initAll, register, toast events, …).
import "basecoat-css/all"

// basecoat only wires its components on DOMContentLoaded, which Turbo
// Drive does not re-fire, and its MutationObserver stays bound to the
// original <body> that Turbo replaces on each visit. Re-run
// initialisation on every Turbo navigation and rebind the observer to
// the new body so tabs, selects, dropdowns and the rest keep working
// after navigating.
//
// Skip the initial turbo:load: it fires right after the DOMContentLoaded
// init, and basecoat's initAll strips the data-*-initialized guards and
// re-inits live elements — the select crashes redefining its value
// property and the duplicated toggle listeners cancel each other out.
let initialTurboLoad = true

document.addEventListener("turbo:load", () => {
  if (initialTurboLoad) {
    initialTurboLoad = false
    return
  }

  window.basecoat.stop()
  window.basecoat.initAll()
  window.basecoat.start()
})
