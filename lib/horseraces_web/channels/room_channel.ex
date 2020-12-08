defmodule HorseracesWeb.RoomChannel do
  use HorseracesWeb, :channel
  require Logger
  require Ecto.Query
  alias HorseracesWeb.Presence
  alias Horseraces.{Users, Repo, Rooms, Cards, ChannelWatcher}


  def join("room:" <> room, _params, socket) do
    uid = socket.assigns.user_id
    :ok = ChannelWatcher.monitor(:room, self(), {__MODULE__, :leave, [room, uid]})
    send(self(), :after_join)
    {:ok, socket}
  end

  def leave(room_id, user_id) do

    res = Rooms |> Ecto.Query.where(roomCode: ^room_id) |> Repo.exists?
    if res do
      # If room exists
      query = Rooms |> Ecto.Query.where(roomCode: ^room_id) |> Repo.one
      case(query.host) do

        # Check who is host
        ^user_id ->
          Users |> Ecto.Query.where(username: ^user_id) |> Repo.delete_all
          case Users |> Ecto.Query.where(roomCode: ^room_id) |> Repo.exists? do
            # If there are still users in the room then do this
            true ->
              users = Users |> Ecto.Query.where(roomCode: ^room_id) |> Repo.all |> Enum.at(0)
              changeset = Rooms.changeset(query, %{roomCode: query.roomCode, isPlaying: query.isPlaying, host: users.username})
              Repo.update(changeset)

              leaving(room_id, user_id, users.username)

            # If you were the last then delete room
            false ->
              Rooms |> Ecto.Query.where(roomCode: ^room_id) |> Repo.delete_all
          end
        _ ->
              unless is_nil(user_id) do
                Users |> Ecto.Query.where(username: ^user_id) |> Repo.delete_all
                leaving(room_id, user_id, "?noNewHostToBeFoundHere")
              end
      end
    end
  end

  def leaving(room_id, user_id, new_host) do
    payload = %{"body" => "?leaving", "name" => new_host, "left" => user_id}
    payload = Map.merge(payload, %{"room" => room_id})
    HorseracesWeb.Endpoint.broadcast("room:" <> room_id, "shout", payload)
  end

  def handle_in("shout", payload, socket) do
    #    payload {"body" => "message", "name" => "username"}
    #    topic is vissible in socket
    case payload["body"] do
      "?bet" ->
        "room:" <> room = socket.topic
        payload = Map.merge(payload, %{"room" => room})
        placeBet(payload["name"], room, payload["color"], payload["bet"])
        checkIfReady(room)
        {:noreply, socket}
      "?cleanLobby" ->
        "room:" <> room = socket.topic
        areLeftovers = Users |> Ecto.Query.where([x], x.roomCode == ^room and x.username != ^payload["name"]) |> Repo.exists?
        if(areLeftovers) do
          Users |> Ecto.Query.where([x], x.roomCode == ^room and x.username != ^payload["name"]) |> Repo.delete_all
        end

        roomHostGhosts = Rooms |> Ecto.Query.where([x], x.roomCode == ^room and x.host != ^payload["name"]) |> Repo.exists?
        if(roomHostGhosts) do
          query = Rooms |> Ecto.Query.where(roomCode: ^room) |> Repo.one
          Rooms.changeset(query, %{roomCode: query.roomCode, isPlaying: query.isPlaying, host: payload["name"]}) |> Repo.update

          payload = %{"body" => "?newHost", "username" => payload["name"]}
          payload = Map.merge(payload, %{"room" => room})
          broadcast socket, "shout", payload
        end

        {:noreply, socket}
      _ ->
        "room:" <> room = socket.topic
        payload = Map.merge(payload, %{"room" => room})
        broadcast socket, "shout", payload
        {:noreply, socket}
    end
  end

  def placeBet(username, roomCode, color, bet) do
    users = Users |> Ecto.Query.where(username: ^username) |> Repo.one
    changeset = Users.changeset(users, %{username: username, roomCode: roomCode, color: color, bet: bet})
    Repo.update(changeset)
  end

  def checkIfReady(roomCode) do
    case Users |> Ecto.Query.where(roomCode: ^roomCode) |> Repo.all |> Enum.filter(fn x -> x.color == "none" end) |> Enum.empty? do
      true ->
        Cards.removeDeck(roomCode)
        Cards.createDeck(roomCode)
        payload = %{"body" => "?letsgo", "username" => "?server"}
        payload = Map.merge(payload, %{"room" => roomCode})
        HorseracesWeb.Endpoint.broadcast("room:" <> roomCode, "shout", payload)
      false ->
        false
    end
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:second)),
      username: socket.assigns.user_id
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

end
