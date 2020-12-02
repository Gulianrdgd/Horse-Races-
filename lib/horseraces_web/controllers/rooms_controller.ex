defmodule HorseracesWeb.RoomsController do
  use HorseracesWeb, :controller
  alias Horseraces.{Repo, Rooms, Users}
  require Ecto.Query
  require Logger

  def checkIfRoomExists(roomCode) do
    _result = Rooms |> Ecto.Query.where(roomCode: ^roomCode) |> Repo.exists?
  end

  def checkIfUserExists(username) do
    _result = Users |> Ecto.Query.where(username: ^username) |> Repo.exists?
  end


  def createRoom(roomCode, username) do
    case Repo.insert(%Rooms{isPlaying: false, roomCode: roomCode, host: username}) do
      {:ok, _struct} -> _result = "Done"
      {:error, _struct} -> _result = "Error"
    end
  end

  def createUser(roomCode, username) do
    case Repo.insert(%Users{username: username, roomCode: roomCode, color: "none", bet: 0}) do
      {:ok, _struct} -> _result = "Done"
      {:error, _struct} -> _result = "Error"
    end
  end

  def show(conn,  %{"id" => room}) do
    render(conn, "game.html")
  end

  def edit(conn,  %{"rooms_id" => room, "id" => username}) do
    case checkIfRoomExists(room) do
      false -> case checkIfUserExists(username) do
            true -> json(conn, "username taken")
            false -> json(conn, createRoom(room, username) <> createUser(room, username))
      end
      true -> case checkIfUserExists(username) do
                true -> json(conn, "username taken")
                false -> json(conn, createUser(room, username))
      end
    end
  end
end
