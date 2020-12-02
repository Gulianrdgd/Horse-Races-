defmodule Horseraces.Users do
  use Ecto.Schema
  import Ecto.Changeset
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

end
