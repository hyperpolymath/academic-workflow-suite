// Type definitions for AWAP Office Add-in

// TMA (Tutor-Marked Assignment) type
type tma = {
  id: option<string>,
  moduleCode: string,
  assignmentNumber: string,
  content: string,
  studentId: option<string>,
  timestamp: float,
}

// Feedback type
type feedback = {
  id: string,
  tmaId: string,
  content: string,
  score: option<float>,
  suggestions: array<string>,
  plagiarismCheck: option<plagiarismResult>,
  generatedAt: float,
}

// Plagiarism check result
and plagiarismResult = {
  score: float,
  matches: array<plagiarismMatch>,
  status: plagiarismStatus,
}

and plagiarismMatch = {
  source: string,
  similarity: float,
  excerpt: string,
}

and plagiarismStatus =
  | Clean
  | Suspicious
  | Flagged

// Settings type
type settings = {
  backendUrl: string,
  apiKey: option<string>,
  moduleCode: option<string>,
  autoSave: bool,
  enableWebSocket: bool,
}

// API Response types
type apiResponse<'a> =
  | Success('a)
  | Error(string)
  | Loading

// WebSocket message types
type wsMessage =
  | FeedbackUpdate(feedback)
  | ProcessingStatus({progress: float, message: string})
  | Error(string)

// Office.js related types
module Office = {
  type coercionType =
    | Text
    | Html
    | Matrix
    | Table

  type asyncResultStatus =
    | Succeeded
    | Failed

  type asyncResult<'a> = {
    status: asyncResultStatus,
    value: option<'a>,
    error: option<asyncError>,
  }

  and asyncError = {
    code: int,
    message: string,
    name: string,
  }

  type getDataOptions = {coercionType: coercionType}

  type setDataOptions = {coercionType: coercionType}
}

// UI State types
type uiState = {
  currentView: view,
  isLoading: bool,
  error: option<string>,
  selectedTmaId: option<string>,
  feedbackPreview: option<feedback>,
}

and view =
  | TmaSelection
  | FeedbackView
  | SettingsView

// Progress indicator
type progress = {
  percentage: float,
  message: string,
  stage: progressStage,
}

and progressStage =
  | Initializing
  | ExtractingContent
  | SendingToBackend
  | ProcessingFeedback
  | Complete
  | Failed

// Helper functions for type conversions
let plagiarismStatusToString = status =>
  switch status {
  | Clean => "clean"
  | Suspicious => "suspicious"
  | Flagged => "flagged"
  }

let plagiarismStatusFromString = str =>
  switch str {
  | "clean" => Some(Clean)
  | "suspicious" => Some(Suspicious)
  | "flagged" => Some(Flagged)
  | _ => None
  }

let coercionTypeToString = ct =>
  switch ct {
  | Text => "text"
  | Html => "html"
  | Matrix => "matrix"
  | Table => "table"
  }

// Default values
let defaultSettings: settings = {
  backendUrl: "http://localhost:8080",
  apiKey: None,
  moduleCode: None,
  autoSave: true,
  enableWebSocket: false,
}

let defaultUiState: uiState = {
  currentView: TmaSelection,
  isLoading: false,
  error: None,
  selectedTmaId: None,
  feedbackPreview: None,
}

// JSON encoding/decoding helpers (simplified - would use proper JSON library in production)
module Json = {
  @val external stringify: 'a => string = "JSON.stringify"
  @val external parse: string => 'a = "JSON.parse"
}
