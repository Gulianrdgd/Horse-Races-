defmodule HorseracesWeb.Router do
  use HorseracesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :internal do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HorseracesWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", HorseracesWeb do
    pipe_through [:internal]

    resources "/room", RoomsController, only: [:show]
  end

  scope "/api", HorseracesWeb do
    pipe_through :api

    resources "/", RoomsController do
      resources "/rooms", RoomsController, only: [:show, :edit]
    end

    resources "/", CardsController do
      resources "/cards", CardsController, only: [:show]
    end

    resources "/", UsersController do
      resources "/users", UsersController, only: [:show]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HorseracesWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HorseracesWeb.Telemetry
    end
  end
end
