// Task Pane UI for AWAP Office Add-in

// DOM manipulation bindings
@val @scope("document")
external getElementById: string => Nullable.t<{..}> = "getElementById"

@val @scope("document")
external querySelector: string => Nullable.t<{..}> = "querySelector"

@val @scope("document")
external createElement: string => {..} = "createElement"

// State management
type state = {
  mutable uiState: Types.uiState,
  mutable settings: Types.settings,
  mutable tmas: array<Types.tma>,
  mutable wsConnection: option<BackendClient.WebSocket.ws>,
}

let appState: state = {
  uiState: Types.defaultUiState,
  settings: Types.defaultSettings,
  tmas: [],
  wsConnection: None,
}

// DOM helpers
let getElement = (id: string): option<{..}> => {
  getElementById(id)->Nullable.toOption
}

let setInnerHTML = (element: {..}, html: string): unit => {
  element["innerHTML"] = html
}

let setValue = (element: {..}, value: string): unit => {
  element["value"] = value
}

let getValue = (element: {..}): string => {
  element["value"]
}

let addEventListener = (element: {..}, event: string, handler: {..} => unit): unit => {
  element["addEventListener"](. event, handler)
}

let show = (element: {..}): unit => {
  element["style"]["display"] = "block"
}

let hide = (element: {..}): unit => {
  element["style"]["display"] = "none"
}

// Load settings from localStorage
let loadSettings = (): unit => {
  appState.settings = RibbonCommands.loadSettings()
  updateSettingsForm()
}

// Update settings form with current values
and updateSettingsForm = (): unit => {
  switch getElement("backendUrl") {
  | Some(elem) => setValue(elem, appState.settings.backendUrl)
  | None => ()
  }

  switch getElement("apiKey") {
  | Some(elem) =>
    setValue(elem, appState.settings.apiKey->Option.getOr(""))
  | None => ()
  }

  switch getElement("moduleCode") {
  | Some(elem) =>
    setValue(elem, appState.settings.moduleCode->Option.getOr(""))
  | None => ()
  }

  switch getElement("autoSave") {
  | Some(elem) => elem["checked"] = appState.settings.autoSave
  | None => ()
  }

  switch getElement("enableWebSocket") {
  | Some(elem) => elem["checked"] = appState.settings.enableWebSocket
  | None => ()
  }
}

// Save settings handler
let handleSaveSettings = (_event: {..}): unit => {
  // Read form values
  let backendUrl = switch getElement("backendUrl") {
  | Some(elem) => getValue(elem)
  | None => appState.settings.backendUrl
  }

  let apiKey = switch getElement("apiKey") {
  | Some(elem) => {
      let val = getValue(elem)
      if String.length(val) > 0 {
        Some(val)
      } else {
        None
      }
    }
  | None => appState.settings.apiKey
  }

  let moduleCode = switch getElement("moduleCode") {
  | Some(elem) => {
      let val = getValue(elem)
      if String.length(val) > 0 {
        Some(val)
      } else {
        None
      }
    }
  | None => appState.settings.moduleCode
  }

  let autoSave = switch getElement("autoSave") {
  | Some(elem) => elem["checked"]
  | None => appState.settings.autoSave
  }

  let enableWebSocket = switch getElement("enableWebSocket") {
  | Some(elem) => elem["checked"]
  | None => appState.settings.enableWebSocket
  }

  // Update state
  appState.settings = {
    backendUrl,
    apiKey,
    moduleCode,
    autoSave,
    enableWebSocket,
  }

  // Save to localStorage
  RibbonCommands.saveSettings(appState.settings)

  // Show confirmation
  showStatus("Settings saved successfully!", "success")

  // Reconnect WebSocket if enabled
  if enableWebSocket {
    connectWebSocket()
  } else {
    disconnectWebSocket()
  }
}

// WebSocket connection
and connectWebSocket = (): unit => {
  // Disconnect existing connection
  disconnectWebSocket()

  let onMessage = (data: string) => {
    try {
      let message = Types.Json.parse(data)
      handleWebSocketMessage(message)
    } catch {
    | _ => Js.Console.error("Failed to parse WebSocket message")
    }
  }

  let onError = (error: {..}) => {
    Js.Console.error2("WebSocket error:", error)
    showStatus("WebSocket connection error", "error")
  }

  let onClose = () => {
    Js.Console.log("WebSocket disconnected")
    appState.wsConnection = None
  }

  let ws = BackendClient.WebSocket.connect(
    appState.settings.backendUrl,
    appState.settings.apiKey,
    onMessage,
    onError,
    onClose,
  )

  appState.wsConnection = Some(ws)
}

and disconnectWebSocket = (): unit => {
  switch appState.wsConnection {
  | Some(ws) => {
      BackendClient.WebSocket.close(ws)
      appState.wsConnection = None
    }
  | None => ()
  }
}

and handleWebSocketMessage = (message: {..}): unit => {
  let msgType = message["type"]

  switch msgType {
  | "feedback_update" => {
      let feedback = message["data"]
      updateFeedbackPreview(feedback)
    }
  | "processing_status" => {
      let progress = message["data"]["progress"]
      let statusMsg = message["data"]["message"]
      updateProgress(progress, statusMsg)
    }
  | "error" => {
      let errorMsg = message["data"]
      showStatus(`Error: ${errorMsg}`, "error")
    }
  | _ => Js.Console.log2("Unknown message type:", msgType)
  }
}

// UI update functions
and showStatus = (message: string, level: string): unit => {
  switch getElement("statusMessage") {
  | Some(elem) => {
      setInnerHTML(elem, message)
      elem["className"] = `status ${level}`
      show(elem)

      // Auto-hide after 5 seconds
      let _ = setTimeout(() => {
        hide(elem)
      }, 5000)
    }
  | None => ()
  }
}

and updateProgress = (percentage: float, message: string): unit => {
  switch getElement("progressBar") {
  | Some(elem) => {
      elem["style"]["width"] = `${Float.toString(percentage)}%`
      elem["setAttribute"](. "aria-valuenow", Float.toString(percentage))
    }
  | None => ()
  }

  switch getElement("progressMessage") {
  | Some(elem) => setInnerHTML(elem, message)
  | None => ()
  }

  switch getElement("progressContainer") {
  | Some(elem) =>
    if percentage >= 100.0 {
      hide(elem)
    } else {
      show(elem)
    }
  | None => ()
  }
}

and updateFeedbackPreview = (feedback: {..}): unit => {
  let html = `
    <div class="feedback-preview">
      <h3>Feedback Preview</h3>
      <div class="feedback-content">
        <p><strong>Score:</strong> ${feedback["score"]->Option.getOr(0.0)->Float.toString}</p>
        <div class="feedback-text">${feedback["content"]}</div>
        ${renderSuggestions(feedback["suggestions"])}
        ${renderPlagiarismCheck(feedback["plagiarismCheck"])}
      </div>
    </div>
  `

  switch getElement("feedbackPreview") {
  | Some(elem) => {
      setInnerHTML(elem, html)
      show(elem)
    }
  | None => ()
  }
}

and renderSuggestions = (suggestions: array<string>): string => {
  if Array.length(suggestions) > 0 {
    let items = suggestions->Array.map(s => `<li>${s}</li>`)->Array.join("")
    `<div class="suggestions">
      <strong>Suggestions:</strong>
      <ul>${items}</ul>
    </div>`
  } else {
    ""
  }
}

and renderPlagiarismCheck = (plagiarismCheck: option<{..}>): string => {
  switch plagiarismCheck {
  | Some(pc) => {
      let statusClass = switch pc["status"] {
      | "clean" => "status-clean"
      | "suspicious" => "status-suspicious"
      | "flagged" => "status-flagged"
      | _ => ""
      }

      `<div class="plagiarism-check ${statusClass}">
        <strong>Plagiarism Check:</strong>
        <p>Score: ${pc["score"]->Float.toString}%</p>
        <p>Status: ${pc["status"]}</p>
      </div>`
    }
  | None => ""
  }
}

// Load TMAs list
let loadTmasList = async (): unit => {
  appState.uiState = {...appState.uiState, isLoading: true}
  updateProgress(30.0, "Loading TMAs...")

  let result = await BackendClient.listTmas(
    appState.settings.backendUrl,
    appState.settings.apiKey,
    appState.settings.moduleCode,
  )

  switch result {
  | Ok(tmas) => {
      appState.tmas = tmas
      updateTmaDropdown(tmas)
      appState.uiState = {...appState.uiState, isLoading: false}
      updateProgress(100.0, "TMAs loaded")
    }
  | Error(err) => {
      showStatus(`Error loading TMAs: ${err}`, "error")
      appState.uiState = {...appState.uiState, isLoading: false}
      updateProgress(0.0, "")
    }
  }
}

and updateTmaDropdown = (tmas: array<Types.tma>): unit => {
  switch getElement("tmaSelect") {
  | Some(elem) => {
      let options = tmas->Array.map(tma => {
        let id = tma.id->Option.getOr("unknown")
        `<option value="${id}">${tma.moduleCode} - ${tma.assignmentNumber}</option>`
      })

      let html =
        `<option value="">Select a TMA...</option>` ++ Array.join(options, "")

      setInnerHTML(elem, html)
    }
  | None => ()
  }
}

// Initialize task pane
let initialize = async (): unit => {
  // Load settings
  loadSettings()

  // Set up event listeners
  switch getElement("saveSettingsBtn") {
  | Some(btn) => addEventListener(btn, "click", handleSaveSettings)
  | None => ()
  }

  switch getElement("refreshTmasBtn") {
  | Some(btn) =>
    addEventListener(btn, "click", _e => {
      let _ = loadTmasList()
    })
  | None => ()
  }

  switch getElement("tmaSelect") {
  | Some(select) =>
    addEventListener(select, "change", event => {
      let tmaId = getValue(event["target"])
      if String.length(tmaId) > 0 {
        appState.uiState = {...appState.uiState, selectedTmaId: Some(tmaId)}
        let _ = loadFeedbackForTma(tmaId)
      }
    })
  | None => ()
  }

  // Load initial data
  let _ = await loadTmasList()

  // Connect WebSocket if enabled
  if appState.settings.enableWebSocket {
    connectWebSocket()
  }

  Js.Console.log("Task pane initialized")
}

and loadFeedbackForTma = async (tmaId: string): unit => {
  updateProgress(50.0, "Loading feedback...")

  let result = await BackendClient.getFeedback(
    appState.settings.backendUrl,
    appState.settings.apiKey,
    tmaId,
  )

  switch result {
  | Ok(feedback) => {
      updateFeedbackPreview(Types.Json.parse(Types.Json.stringify(feedback)))
      updateProgress(100.0, "Feedback loaded")
    }
  | Error(err) => {
      showStatus(`Error loading feedback: ${err}`, "error")
      updateProgress(0.0, "")
    }
  }
}

// Run initialization when DOM is ready
@val @scope("document")
external addEventListener: (string, unit => unit) => unit = "addEventListener"

let run = (): unit => {
  addEventListener("DOMContentLoaded", () => {
    let _ = initialize()
  })
}
