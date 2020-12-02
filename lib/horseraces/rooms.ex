defmodule Horseraces.Rooms do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  schema "rooms" do
    field :isPlaying, :boolean
    field :roomCode, :string
    field :host, :string
    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:isPlaying, :roomCode, :host])
    |> validate_required([ :isPlaying, :roomCode, :host])
  end

end
