defmodule Horseraces.Users do
  use Ecto.Schema
  import Ecto.Changeset
  alias Horseraces.{Repo, Users}
  require Ecto.Query
  require Logger

  schema "users" do
    field :username, :string
    field :roomCode, :string
    field :color, :string
    field :bet, :integer
    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:username, :roomCode, :color, :bet])
    |> validate_required([:username, :roomCode, :color, :bet])
  end

  def getWinners(roomCode, color) do
    query = Users |> Ecto.Query.where(roomCode: ^roomCode, color: ^color) |> Repo.all |> Enum.map(fn user -> [user.username, to_string(user.bet)] end)
  end

end
