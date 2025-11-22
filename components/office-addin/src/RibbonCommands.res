// Ribbon command handlers for AWAP Office Add-in

// Local storage bindings for settings
@val @scope("localStorage")
external getItem: string => Nullable.t<string> = "getItem"

@val @scope("localStorage")
external setItem: (string, string) => unit = "setItem"

// Load settings from localStorage
let loadSettings = (): Types.settings => {
  try {
    let settingsJson = getItem("awap-settings")

    switch settingsJson->Nullable.toOption {
    | Some(json) => {
        let parsed = Types.Json.parse(json)
        {
          backendUrl: parsed["backendUrl"],
          apiKey: parsed["apiKey"],
          moduleCode: parsed["moduleCode"],
          autoSave: parsed["autoSave"],
          enableWebSocket: parsed["enableWebSocket"],
        }
      }
    | None => Types.defaultSettings
    }
  } catch {
  | _ => Types.defaultSettings
  }
}

// Save settings to localStorage
let saveSettings = (settings: Types.settings): unit => {
  try {
    let json = Types.Json.stringify(settings)
    setItem("awap-settings", json)
  } catch {
  | _ => Js.Console.error("Failed to save settings")
  }
}

// Show user feedback (temporary implementation using alert)
@val external alert: string => unit = "alert"

let showMessage = (message: string): unit => {
  alert(message)
}

// Mark TMA command - Extract selected TMA content and send to backend
let markTMA = async (_event: {..}): unit => {
  try {
    // Load settings
    let settings = loadSettings()

    // Get selected content from document
    let contentResult = await OfficeAPI.getSelectedData(Types.Office.Text)

    switch contentResult {
    | Ok(content) => {
        if String.length(content) === 0 {
          showMessage("Please select content to mark as TMA")
        } else {
          // Create TMA object
          let tma: Types.tma = {
            id: None,
            moduleCode: settings.moduleCode->Option.getOr("UNKNOWN"),
            assignmentNumber: "TMA-" ++ Float.toString(Date.now()),
            content: content,
            studentId: None,
            timestamp: Date.now(),
          }

          // Submit to backend
          let submitResult = await BackendClient.submitTma(
            settings.backendUrl,
            settings.apiKey,
            tma,
          )

          switch submitResult {
          | Ok(tmaId) => {
              // Save TMA ID to localStorage for later reference
              setItem("awap-last-tma-id", tmaId)
              showMessage(`TMA successfully submitted! ID: ${tmaId}`)
            }
          | Error(err) => showMessage(`Error submitting TMA: ${err}`)
          }
        }
      }
    | Error(err) => showMessage(`Error reading selection: ${err}`)
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Unknown error")
      showMessage(`Error: ${message}`)
    }
  | _ => showMessage("Unexpected error occurred")
  }
}

// Generate Feedback command - Trigger AI feedback generation
let generateFeedback = async (_event: {..}): unit => {
  try {
    // Load settings
    let settings = loadSettings()

    // Get last TMA ID
    let lastTmaId = getItem("awap-last-tma-id")

    switch lastTmaId->Nullable.toOption {
    | Some(tmaId) => {
        // Request feedback generation
        let result = await BackendClient.requestFeedbackGeneration(
          settings.backendUrl,
          settings.apiKey,
          tmaId,
        )

        switch result {
        | Ok() => {
            showMessage("Feedback generation started. Check back in a few moments.")

            // Optionally, start polling for feedback
            if settings.enableWebSocket === false {
              // Poll for feedback after a delay
              let _ = setTimeout(() => {
                pollForFeedback(tmaId, settings)
              }, 5000)
            }
          }
        | Error(err) => showMessage(`Error requesting feedback: ${err}`)
        }
      }
    | None =>
      showMessage("No TMA found. Please mark a TMA first using the 'Mark TMA' button.")
    }
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Unknown error")
      showMessage(`Error: ${message}`)
    }
  | _ => showMessage("Unexpected error occurred")
  }
}

// Poll for feedback (fallback when WebSocket is not enabled)
and pollForFeedback = async (tmaId: string, settings: Types.settings): unit => {
  try {
    let result = await BackendClient.getFeedback(settings.backendUrl, settings.apiKey, tmaId)

    switch result {
    | Ok(feedback) => {
        // Store feedback
        setItem("awap-last-feedback", Types.Json.stringify(feedback))

        // Insert feedback into document
        let feedbackText =
          `\n\n--- FEEDBACK ---\n${feedback.content}\n\nScore: ${feedback.score->Option.getOr(0.0)->Float.toString}\n\n`

        let _ = await OfficeAPI.insertText(feedbackText)

        showMessage("Feedback has been inserted into the document!")
      }
    | Error(err) => {
        // Feedback might not be ready yet
        Js.Console.log(`Feedback not ready: ${err}`)
      }
    }
  } catch {
  | _ => Js.Console.error("Error polling for feedback")
  }
}

// Open Settings command - Show task pane
@val @scope(("Office", "context", "ui"))
external displayDialogAsync: (string, {..}, {..} => unit) => unit = "displayDialogAsync"

let openSettings = (_event: {..}): unit => {
  // The Settings button in manifest.xml is configured to show the task pane
  // This function is here for completeness but won't be called
  // since the manifest handles it via ShowTaskpane action
  Js.Console.log("Settings opened via task pane")
}

// Register commands globally for Office.js
@set external setMarkTMA: (. string, {..} => promise<unit>) = "markTMA"
@set external setGenerateFeedback: (. string, {..} => promise<unit>) = "generateFeedback"
@set external setOpenSettings: (. string, {..} => unit) = "openSettings"

let registerCommands = (): unit => {
  // Register commands on global object for Office.js to call
  setMarkTMA(. "markTMA", markTMA)
  setGenerateFeedback(. "generateFeedback", generateFeedback)
  setOpenSettings(. "openSettings", openSettings)

  Js.Console.log("Ribbon commands registered")
}

// Export for testing
let exportedForTesting = {
  "loadSettings": loadSettings,
  "saveSettings": saveSettings,
  "markTMA": markTMA,
  "generateFeedback": generateFeedback,
  "openSettings": openSettings,
}
