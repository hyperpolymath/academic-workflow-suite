// Main entry point for AWAP Office Add-in

// Add-in lifecycle state
type addinState = {
  mutable isInitialized: bool,
  mutable officeReady: bool,
  mutable currentPage: page,
}

and page =
  | CommandsPage
  | TaskPanePage
  | Unknown

let state: addinState = {
  isInitialized: false,
  officeReady: false,
  currentPage: Unknown,
}

// Determine which page we're on
@val @scope(("window", "location"))
external pathname: string = "pathname"

let detectPage = (): page => {
  if pathname->String.includes("commands.html") {
    CommandsPage
  } else if pathname->String.includes("taskpane.html") {
    TaskPanePage
  } else {
    Unknown
  }
}

// Initialize Office.js
let initializeOffice = async (): result<unit, string> => {
  try {
    Js.Console.log("Initializing Office.js...")

    let result = await OfficeAPI.initialize()

    switch result {
    | Ok() => {
        state.officeReady = true
        Js.Console.log("Office.js initialized successfully")

        // Check host type
        let hostType = OfficeAPI.getHostType()
        switch hostType {
        | Word => Js.Console.log("Running in Microsoft Word")
        | Excel => Js.Console.log("Running in Microsoft Excel")
        | PowerPoint => Js.Console.log("Running in Microsoft PowerPoint")
        | Outlook => Js.Console.log("Running in Microsoft Outlook")
        | Unknown => Js.Console.warn("Unknown Office host")
        }

        Ok()
      }
    | Error(err) => Error(err)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to initialize Office.js")
      Error(message)
    }
  | _ => Error("Unexpected error initializing Office.js")
  }
}

// Initialize commands page
let initializeCommandsPage = (): unit => {
  Js.Console.log("Initializing Commands Page...")

  // Register ribbon commands
  RibbonCommands.registerCommands()

  Js.Console.log("Commands Page initialized")
}

// Initialize task pane page
let initializeTaskPanePage = (): unit => {
  Js.Console.log("Initializing Task Pane...")

  // Run task pane initialization
  TaskPane.run()

  Js.Console.log("Task Pane initialized")
}

// Main initialization function
let initialize = async (): unit => {
  if state.isInitialized {
    Js.Console.warn("Add-in already initialized")
  } else {
    try {
      Js.Console.log("Starting AWAP Office Add-in initialization...")

      // Detect current page
      state.currentPage = detectPage()

      switch state.currentPage {
      | CommandsPage => {
          Js.Console.log("Detected Commands Page")
          // Initialize Office.js first
          let officeResult = await initializeOffice()

          switch officeResult {
          | Ok() => {
              initializeCommandsPage()
              state.isInitialized = true
            }
          | Error(err) => {
              Js.Console.error2("Failed to initialize Office.js:", err)
            }
          }
        }
      | TaskPanePage => {
          Js.Console.log("Detected Task Pane Page")
          // Initialize Office.js first
          let officeResult = await initializeOffice()

          switch officeResult {
          | Ok() => {
              initializeTaskPanePage()
              state.isInitialized = true
            }
          | Error(err) => {
              Js.Console.error2("Failed to initialize Office.js:", err)
            }
          }
        }
      | Unknown => {
          Js.Console.warn("Unknown page type, skipping initialization")
        }
      }

      if state.isInitialized {
        Js.Console.log("AWAP Office Add-in initialized successfully!")
      }
    } catch {
    | Js.Exn.Error(err) => {
        let message = Js.Exn.message(err)->Option.getOr("Unknown error")
        Js.Console.error2("Initialization error:", message)
      }
    | _ => Js.Console.error("Unexpected initialization error")
    }
  }
}

// Check add-in health
let healthCheck = async (): result<bool, string> => {
  // Check if Office.js is ready
  if !state.officeReady {
    Error("Office.js not ready")
  } else if !OfficeAPI.isOfficeContext() {
    Error("Not running in Office context")
  } else {
    // Check backend connectivity (using settings from localStorage)
    let settings = RibbonCommands.loadSettings()
    let backendHealth = await BackendClient.healthCheck(settings.backendUrl)

    switch backendHealth {
    | Ok(healthy) =>
      if healthy {
        Ok(true)
      } else {
        Error("Backend is not healthy")
      }
    | Error(err) => Error(`Backend health check failed: ${err}`)
    }
  }
}

// Shutdown/cleanup
let shutdown = (): unit => {
  Js.Console.log("Shutting down AWAP Office Add-in...")

  // Disconnect WebSocket if on task pane
  if state.currentPage === TaskPanePage {
    // TaskPane will handle its own cleanup
  }

  state.isInitialized = false
  state.officeReady = false

  Js.Console.log("Add-in shutdown complete")
}

// Error boundary for global errors
@val @scope("window")
external addEventListener: (string, {..} => unit) => unit = "addEventListener"

let setupErrorHandlers = (): unit => {
  addEventListener("error", event => {
    Js.Console.error2("Global error:", event["error"])
  })

  addEventListener("unhandledrejection", event => {
    Js.Console.error2("Unhandled promise rejection:", event["reason"])
  })
}

// Auto-initialize when script loads
let run = (): unit => {
  setupErrorHandlers()

  // Wait for Office to be ready
  @val @scope("Office")
  external onReady: (. unit => unit) => unit = "onReady"

  onReady(. () => {
    let _ = initialize()
  })
}

// Export for manual initialization if needed
let exportedApi = {
  "initialize": initialize,
  "healthCheck": healthCheck,
  "shutdown": shutdown,
  "getState": () => state,
}

// Make API available globally for debugging
@set external setGlobalAwap: {..} => unit = "AWAP"
setGlobalAwap(exportedApi)

// Auto-run on script load
run()
