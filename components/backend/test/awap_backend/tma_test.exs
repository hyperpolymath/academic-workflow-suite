defmodule AwapBackend.TMATest do
  @moduledoc """
  Tests for the TMA context module.
  """

  use AwapBackend.DataCase

  alias AwapBackend.TMA

  describe "create_tma/1" do
    test "creates a TMA with valid attributes" do
      attrs = %{
        assignment_id: "assignment_123",
        student_id: "student_456",
        course_id: "course_789",
        content: %{
          answers: ["Answer 1", "Answer 2"],
          attachments: []
        }
      }

      assert {:ok, tma} = TMA.create_tma(attrs)
      assert tma.assignment_id == "assignment_123"
      assert tma.student_id == "student_456"
      assert tma.course_id == "course_789"
      assert tma.status == :pending
    end

    test "returns error with invalid attributes" do
      attrs = %{
        assignment_id: nil,
        student_id: "student_456"
      }

      assert {:error, changeset} = TMA.create_tma(attrs)
      assert %{assignment_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "get_tma/1" do
    test "returns TMA when it exists" do
      {:ok, tma} = create_test_tma()

      assert {:ok, found_tma} = TMA.get_tma(tma.id)
      assert found_tma.id == tma.id
    end

    test "returns error when TMA does not exist" do
      assert {:error, :not_found} = TMA.get_tma(Ecto.UUID.generate())
    end
  end

  describe "update_with_feedback/3" do
    test "updates TMA with feedback" do
      {:ok, tma} = create_test_tma()
      job_id = Ecto.UUID.generate()

      feedback_data = %{
        grade: 85.5,
        feedback_text: "Good work overall",
        strengths: ["Clear writing", "Good structure"],
        improvements: ["Add more examples"]
      }

      assert {:ok, updated_tma} = TMA.update_with_feedback(tma.id, job_id, feedback_data)
      assert updated_tma.status == :completed
      assert updated_tma.job_id == job_id
    end
  end

  describe "list_tmas/1" do
    test "lists TMAs with default limit" do
      {:ok, _tma1} = create_test_tma()
      {:ok, _tma2} = create_test_tma()

      tmas = TMA.list_tmas()
      assert length(tmas) == 2
    end

    test "filters TMAs by status" do
      {:ok, tma1} = create_test_tma()
      {:ok, _tma2} = create_test_tma()

      # Update one TMA to completed
      TMA.update_with_feedback(tma1.id, Ecto.UUID.generate(), %{
        feedback_text: "Test feedback"
      })

      pending_tmas = TMA.list_tmas(status: :pending)
      assert length(pending_tmas) == 1

      completed_tmas = TMA.list_tmas(status: :completed)
      assert length(completed_tmas) == 1
    end
  end

  # Helper Functions

  defp create_test_tma do
    TMA.create_tma(%{
      assignment_id: "assignment_#{:rand.uniform(1000)}",
      student_id: "student_#{:rand.uniform(1000)}",
      course_id: "course_#{:rand.uniform(1000)}",
      content: %{
        answers: ["Test answer"],
        attachments: []
      }
    })
  end
end
