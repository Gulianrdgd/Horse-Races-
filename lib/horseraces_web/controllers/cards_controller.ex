defmodule HorseracesWeb.CardsController do
  use HorseracesWeb, :controller
  alias Horseraces.{Cards}

  def show(conn,  %{"cards_id" => roomCode, "id" => "getCard"}) do
    payload = %{"body" => "?nextCard", "username" => "?server", "card" => Cards.getCard(roomCode)}
    payload = Map.merge(payload, %{"room" => roomCode})
    HorseracesWeb.Endpoint.broadcast("room:" <> roomCode, "shout", payload)
    json(conn, "done")
  end

end
