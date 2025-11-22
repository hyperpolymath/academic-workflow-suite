// Office.js API bindings for ReScript

// External bindings to Office.js global objects
@val @scope("Office")
external onReady: (. unit => unit) => unit = "onReady"

@val @scope("Office") @scope("context") @scope("document")
external getSelectedDataAsync: (. string, {..}, (. {..}) => unit) => unit = "getSelectedDataAsync"

@val @scope("Office") @scope("context") @scope("document")
external setSelectedDataAsync: (. string, {..}, (. {..}) => unit) => unit = "setSelectedDataAsync"

@val @scope("Office") @scope("context") @scope("document")
external getFileAsync: (. int, {..}, (. {..}) => unit) => unit = "getFileAsync"

@val @scope("Office") @scope("context")
external displayDialogAsync: (. string, {..}, (. {..}) => unit) => unit = "displayDialogAsync"

// Constants for coercion types
module CoercionType = {
  @val @scope(("Office", "CoercionType")) external text: string = "Text"
  @val @scope(("Office", "CoercionType")) external html: string = "Html"
  @val @scope(("Office", "CoercionType")) external matrix: string = "Matrix"
  @val @scope(("Office", "CoercionType")) external table: string = "Table"
}

// Constants for async result status
module AsyncResultStatus = {
  @val @scope(("Office", "AsyncResultStatus")) external succeeded: string = "Succeeded"
  @val @scope(("Office", "AsyncResultStatus")) external failed: string = "Failed"
}

// Helper to convert Types.Office.coercionType to string
let coercionTypeToString = (ct: Types.Office.coercionType) =>
  switch ct {
  | Text => CoercionType.text
  | Html => CoercionType.html
  | Matrix => CoercionType.matrix
  | Table => CoercionType.table
  }

// Safe wrapper for getSelectedDataAsync
let getSelectedData = async (coercionType: Types.Office.coercionType): result<string, string> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      let options = {"coercionType": coercionTypeToString(coercionType)}

      getSelectedDataAsync(. CoercionType.text, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          let value = asyncResult["value"]
          switch value {
          | Some(v) => resolve(Ok(v))
          | None => resolve(Error("No data selected"))
          }
        } else {
          let error = asyncResult["error"]
          let errorMsg = switch error {
          | Some(err) => err["message"]
          | None => "Unknown error occurred"
          }
          resolve(Error(errorMsg))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to get selected data")
      Error(message)
    }
  | _ => Error("Unexpected error in getSelectedData")
  }
}

// Safe wrapper for setSelectedDataAsync
let setSelectedData = async (data: string, coercionType: Types.Office.coercionType): result<
  unit,
  string,
> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      let options = {"coercionType": coercionTypeToString(coercionType)}

      setSelectedDataAsync(. data, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          resolve(Ok())
        } else {
          let error = asyncResult["error"]
          let errorMsg = switch error {
          | Some(err) => err["message"]
          | None => "Unknown error occurred"
          }
          resolve(Error(errorMsg))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to set selected data")
      Error(message)
    }
  | _ => Error("Unexpected error in setSelectedData")
  }
}

// Get entire document content
let getDocumentContent = async (): result<string, string> => {
  try {
    // For Word, we'll use the Word API to get the whole document
    // This is a simplified version - real implementation would use Word.run
    let promise = Promise.make((resolve, _reject) => {
      // Fallback: ask user to select all content
      let options = {"coercionType": CoercionType.text}

      getSelectedDataAsync(. CoercionType.text, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          let value = asyncResult["value"]
          switch value {
          | Some(v) => resolve(Ok(v))
          | None => resolve(Error("No content found"))
          }
        } else {
          resolve(Error("Please select the content you want to process"))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to get document content")
      Error(message)
    }
  | _ => Error("Unexpected error in getDocumentContent")
  }
}

// Insert text at current position
let insertText = async (text: string): result<unit, string> => {
  await setSelectedData(text, Text)
}

// Insert HTML at current position
let insertHtml = async (html: string): result<unit, string> => {
  await setSelectedData(html, Html)
}

// Show notification to user
@val @scope(("Office", "context", "ui"))
external displayDialogAsyncRaw: (. string, {..}, (. {..}) => unit) => unit = "displayDialogAsync"

let showNotification = (title: string, message: string): unit => {
  // Office.js doesn't have built-in notifications for Word
  // We'll use console.log for now, or implement a custom dialog
  Js.Console.log2(title, message)
}

// Initialize Office.js
let initialize = async (): result<unit, string> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      onReady(. () => {
        resolve(Ok())
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to initialize Office.js")
      Error(message)
    }
  | _ => Error("Unexpected error in Office.js initialization")
  }
}

// Check if running in Office context
@val @scope("Office")
external context: {..} = "context"

let isOfficeContext = (): bool => {
  try {
    let _ = context
    true
  } catch {
  | _ => false
  }
}

// Get host info
@val @scope(("Office", "context"))
external host: {..} = "host"

type hostType = Word | Excel | PowerPoint | Outlook | Unknown

let getHostType = (): hostType => {
  try {
    let hostName = host["type"]
    switch hostName {
    | "Word" => Word
    | "Excel" => Excel
    | "PowerPoint" => PowerPoint
    | "Outlook" => Outlook
    | _ => Unknown
    }
  } catch {
  | _ => Unknown
  }
}

// Event handlers
type eventHandler = unit => unit

let onSelectionChanged = (handler: eventHandler): unit => {
  // Office.context.document.addHandlerAsync would be used here
  // Simplified for now
  let _ = handler
  ()
}
