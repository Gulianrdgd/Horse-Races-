defmodule HorseracesWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "room:*", HorseracesWeb.RoomChannel

  @impl true
  def connect(params, socket, _connect_info) do
    cond do
      params["username"] == "" ->
        {:error, %{reason: "No username provided."}, socket}
      true ->
        username = params["username"]
        {:ok, assign(socket, :user_id, username)}
    end
  end

  @impl true
  def id(_socket), do: nil
end
