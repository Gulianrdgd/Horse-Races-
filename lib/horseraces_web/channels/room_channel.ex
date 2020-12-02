defmodule HorseracesWeb.RoomChannel do
  use HorseracesWeb, :channel
  require Logger
  require Ecto.Query
  alias HorseracesWeb.Presence
  alias Horseraces.{Users, Repo, Rooms, ChannelWatcher}


  def join("room:" <> room, _params, socket) do
    uid = socket.assigns.user_id
    :ok = ChannelWatcher.monitor(:room, self(), {__MODULE__, :leave, [room, uid]})
    send(self(), :after_join)

    res = Users |> Ecto.Query.where(username: ^uid) |> Repo.exists?
    if !res do
      changeset = Users.changeset(%Users{}, %{username: uid, roomCode: room, color: "", bet: 0})
      Repo.insert(changeset)
    end

    res = Rooms |> Ecto.Query.where(roomCode: ^room) |> Repo.exists?
    if !res do
      changeset = Rooms.changeset(%Rooms{}, %{roomCode: room , isPlaying: false, host: uid})
      Repo.insert(changeset)
    end
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
              users = Users |> Ecto.Query.where(roomCode: ^room_id) |> Repo.one
              changeset = Rooms.changeset(query, %{roomCode: query.roomCode, isPlaying: query.isPlaying, host: users.username})
              Repo.update(changeset)
              # If you were the last then delete room
              leaving(room_id, user_id, users.username)

            false ->
              Rooms |> Ecto.Query.where(roomCode: ^room_id) |> Repo.delete_all
          end

        _ ->  Users |> Ecto.Query.where(username: ^user_id) |> Repo.delete_all
              leaving(room_id, user_id, "?noNewHostToBeFoundHere")
      end
    end
  end

  def leaving(room_id, user_id, new_host) do
    payload = %{"body" => "?leaving", "name" => new_host, "left" => user_id}
    payload = Map.merge(payload, %{"room" => room_id})
    HorseracesWeb.Endpoint.broadcast("chat:" <> room_id, "shout", payload)
  end

  def handle_in("shout", payload, socket) do
    #    payload {"body" => "message", "name" => "username"}
    #    topic is vissible in socket
    case payload["body"] do
      _ ->
        "chat:" <> room = socket.topic
        payload = Map.merge(payload, %{"room" => room})
        broadcast socket, "shout", payload
        {:noreply, socket}
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
