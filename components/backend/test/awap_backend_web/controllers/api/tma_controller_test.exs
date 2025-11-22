defmodule AwapBackendWeb.API.TMAControllerTest do
  @moduledoc """
  Tests for the TMA API controller.
  """

  use AwapBackendWeb.ConnCase

  alias AwapBackend.TMA

  describe "POST /api/tmas" do
    test "creates a TMA with valid attributes", %{conn: conn} do
      attrs = %{
        "assignment_id" => "assignment_123",
        "student_id" => "student_456",
        "course_id" => "course_789",
        "content" => %{
          "answers" => ["Answer 1", "Answer 2"],
          "attachments" => []
        }
      }

      conn = post(conn, Routes.tma_path(conn, :create), attrs)
      assert %{"id" => id, "status" => "pending"} = json_response(conn, 201)
      assert is_binary(id)
    end

    test "returns error with invalid attributes", %{conn: conn} do
      attrs = %{
        "student_id" => "student_456"
      }

      conn = post(conn, Routes.tma_path(conn, :create), attrs)
      assert %{"errors" => _errors} = json_response(conn, 422)
    end
  end

  describe "GET /api/tmas/:id" do
    test "returns TMA when it exists", %{conn: conn} do
      {:ok, tma} = create_test_tma()

      conn = get(conn, Routes.tma_path(conn, :show, tma.id))
      assert %{"id" => id, "status" => "pending"} = json_response(conn, 200)
      assert id == tma.id
    end

    test "returns 404 when TMA does not exist", %{conn: conn} do
      conn = get(conn, Routes.tma_path(conn, :show, Ecto.UUID.generate()))
      assert %{"error" => "TMA not found"} = json_response(conn, 404)
    end
  end

  describe "GET /api/tmas" do
    test "lists TMAs", %{conn: conn} do
      {:ok, _tma1} = create_test_tma()
      {:ok, _tma2} = create_test_tma()

      conn = get(conn, Routes.tma_path(conn, :index))
      assert %{"tmas" => tmas} = json_response(conn, 200)
      assert length(tmas) == 2
    end

    test "filters TMAs by status", %{conn: conn} do
      {:ok, _tma} = create_test_tma()

      conn = get(conn, Routes.tma_path(conn, :index, status: "pending"))
      assert %{"tmas" => tmas} = json_response(conn, 200)
      assert length(tmas) >= 1
    end
  end

  describe "GET /api/feedback/:tma_id" do
    test "returns feedback when it exists", %{conn: conn} do
      {:ok, tma} = create_test_tma()
      {:ok, _updated_tma} = create_test_feedback(tma.id)

      conn = get(conn, "/api/feedback/#{tma.id}")
      assert %{"tma_id" => tma_id, "feedback_text" => _text} = json_response(conn, 200)
      assert tma_id == tma.id
    end

    test "returns 404 when feedback does not exist", %{conn: conn} do
      {:ok, tma} = create_test_tma()

      conn = get(conn, "/api/feedback/#{tma.id}")
      assert %{"error" => _message} = json_response(conn, 404)
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

  defp create_test_feedback(tma_id) do
    TMA.update_with_feedback(tma_id, Ecto.UUID.generate(), %{
      grade: 85.5,
      feedback_text: "Good work",
      strengths: ["Clear writing"],
      improvements: ["Add examples"]
    })
  end
end
