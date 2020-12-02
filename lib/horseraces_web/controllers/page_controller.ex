defmodule HorseracesWeb.PageController do
  use HorseracesWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
