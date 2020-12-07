defmodule HorseracesWeb.UsersController do
  use HorseracesWeb, :controller
  alias Horseraces.{Users}

  def show(conn,  %{"users_id" => room, "id" => winner}) do
    json(conn, Users.getWinners(room, winner))
  end
end
