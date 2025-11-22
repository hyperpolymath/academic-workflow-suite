# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AwapBackend.Repo.insert!(%AwapBackend.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AwapBackend.Repo
alias AwapBackend.TMA

# Example seed data for development
if Mix.env() == :dev do
  IO.puts("Seeding development database...")

  # Create sample TMAs
  {:ok, _tma1} =
    TMA.create_tma(%{
      assignment_id: "assignment_001",
      student_id: "student_alice",
      course_id: "course_cs101",
      content: %{
        answers: [
          "The time complexity of binary search is O(log n).",
          "Quick sort has an average case complexity of O(n log n)."
        ],
        attachments: []
      }
    })

  {:ok, _tma2} =
    TMA.create_tma(%{
      assignment_id: "assignment_001",
      student_id: "student_bob",
      course_id: "course_cs101",
      content: %{
        answers: [
          "Binary search works by repeatedly dividing the search space in half.",
          "The worst case for bubble sort is O(n^2)."
        ],
        attachments: []
      }
    })

  IO.puts("Created 2 sample TMAs")
end
