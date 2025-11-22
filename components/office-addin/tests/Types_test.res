// Tests for Types module

open Jest
open Expect

describe("Types", () => {
  describe("plagiarismStatusToString", () => {
    test("converts Clean to 'clean'", () => {
      expect(Types.plagiarismStatusToString(Types.Clean))->toBe("clean")
    })

    test("converts Suspicious to 'suspicious'", () => {
      expect(Types.plagiarismStatusToString(Types.Suspicious))->toBe("suspicious")
    })

    test("converts Flagged to 'flagged'", () => {
      expect(Types.plagiarismStatusToString(Types.Flagged))->toBe("flagged")
    })
  })

  describe("plagiarismStatusFromString", () => {
    test("converts 'clean' to Clean", () => {
      expect(Types.plagiarismStatusFromString("clean"))->toEqual(Some(Types.Clean))
    })

    test("converts 'suspicious' to Suspicious", () => {
      expect(Types.plagiarismStatusFromString("suspicious"))->toEqual(Some(Types.Suspicious))
    })

    test("converts 'flagged' to Flagged", () => {
      expect(Types.plagiarismStatusFromString("flagged"))->toEqual(Some(Types.Flagged))
    })

    test("returns None for invalid status", () => {
      expect(Types.plagiarismStatusFromString("invalid"))->toEqual(None)
    })
  })

  describe("coercionTypeToString", () => {
    test("converts Text to 'text'", () => {
      expect(Types.coercionTypeToString(Types.Office.Text))->toBe("text")
    })

    test("converts Html to 'html'", () => {
      expect(Types.coercionTypeToString(Types.Office.Html))->toBe("html")
    })

    test("converts Matrix to 'matrix'", () => {
      expect(Types.coercionTypeToString(Types.Office.Matrix))->toBe("matrix")
    })

    test("converts Table to 'table'", () => {
      expect(Types.coercionTypeToString(Types.Office.Table))->toBe("table")
    })
  })

  describe("defaultSettings", () => {
    test("has correct default backendUrl", () => {
      expect(Types.defaultSettings.backendUrl)->toBe("http://localhost:8080")
    })

    test("has None for apiKey", () => {
      expect(Types.defaultSettings.apiKey)->toEqual(None)
    })

    test("has None for moduleCode", () => {
      expect(Types.defaultSettings.moduleCode)->toEqual(None)
    })

    test("has autoSave enabled", () => {
      expect(Types.defaultSettings.autoSave)->toBe(true)
    })

    test("has WebSocket disabled", () => {
      expect(Types.defaultSettings.enableWebSocket)->toBe(false)
    })
  })

  describe("defaultUiState", () => {
    test("starts with TmaSelection view", () => {
      expect(Types.defaultUiState.currentView)->toEqual(Types.TmaSelection)
    })

    test("is not loading initially", () => {
      expect(Types.defaultUiState.isLoading)->toBe(false)
    })

    test("has no error initially", () => {
      expect(Types.defaultUiState.error)->toEqual(None)
    })

    test("has no selected TMA initially", () => {
      expect(Types.defaultUiState.selectedTmaId)->toEqual(None)
    })

    test("has no feedback preview initially", () => {
      expect(Types.defaultUiState.feedbackPreview)->toEqual(None)
    })
  })

  describe("TMA creation", () => {
    test("creates a valid TMA object", () => {
      let tma: Types.tma = {
        id: Some("tma-123"),
        moduleCode: "CS101",
        assignmentNumber: "TMA-01",
        content: "Test content",
        studentId: Some("student-456"),
        timestamp: 1234567890.0,
      }

      expect(tma.moduleCode)->toBe("CS101")
      expect(tma.assignmentNumber)->toBe("TMA-01")
      expect(tma.content)->toBe("Test content")
    })
  })

  describe("Feedback creation", () => {
    test("creates a valid feedback object", () => {
      let feedback: Types.feedback = {
        id: "feedback-123",
        tmaId: "tma-123",
        content: "Good work!",
        score: Some(85.5),
        suggestions: ["Improve introduction", "Add more references"],
        plagiarismCheck: None,
        generatedAt: 1234567890.0,
      }

      expect(feedback.content)->toBe("Good work!")
      expect(feedback.score)->toEqual(Some(85.5))
      expect(Array.length(feedback.suggestions))->toBe(2)
    })
  })
})
