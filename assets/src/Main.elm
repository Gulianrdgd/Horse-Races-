port module Main exposing (..)

import Browser
import Browser.Navigation exposing (load)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http

import Loading
  exposing
      ( LoaderType(..)
      , defaultConfig
      )
import Platform.Cmd exposing (batch)
import String exposing (slice, toLower)

-- MAIN

main : Program { url : String } Model Msg
main =
  Browser.element { init = \{ url } -> ( init url, Cmd.none ), update = update, subscriptions = subscriptions, view = view }


-- MODEL
port sendMessage : String -> Cmd msg
port messageReceiver : (String -> msg) -> Sub msg

type alias Model =
  { username : String
  , roomCode : String
  , submit: Bool
  , response: String
  , url: String
  }


init : String -> Model
init str =
  Model "" "" False "" str

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

type Msg
  = Username String
  | RoomCode String
  | Submit Bool
  | Response (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Username username ->
      ({ model | username = username }, Cmd.none)

    RoomCode roomCode ->
      ({ model | roomCode = roomCode }, Cmd.none)

    Submit b ->
        ({ model | submit = b },
            Http.get {url = model.url ++ "api/" ++  model.roomCode ++ "/rooms/" ++ model.username ++ "/edit", expect = Http.expectString Response }
        )
    Response res ->
        case res of
           Ok val -> case slice 1 -1 val of
                      "DoneDone" -> ( model, batch [sendMessage ("?username:" ++ model.username), sendMessage ("?isHost:" ++ "Y"), load (model.url ++ "room/" ++ model.roomCode)] )
                      "Done" -> ( model, batch [sendMessage ("?username:" ++ model.username), sendMessage ("?isHost:" ++ "N"), load (model.url ++ "room/" ++ model.roomCode)] )
                      _-> ({ model | response = slice 1 -1 val}, Cmd.none)
           Err _ -> ({ model | response = "err"}, Cmd.none)


view : Model -> Html Msg
view model =
    if model.submit && model.response == "init" then
       div [ class "container"]
           [ Loading.render
               DoubleBounce -- LoaderType
               { defaultConfig | color = "#FFF" } -- Config
               Loading.On -- LoadingState
           ]
    else
       div [class "container columns fade is-vertical-center", style "margin-top" "13rem"]
           [
              div [class "column is-one-fifth is-flex is-horizontal-center"]
                  [
                    img [src "/images/thalia.svg", class ""] []
                  ],
              div  [class "column container form fade", style "margin" "auto"]
                   [ p [class "subtitle is-5 has-text-white", style "margin-bottom" "0.3rem"] [text "Enter a username"]
                   , viewInput "text" "Username" model.username Username
                   , p [class "subtitle is-5 has-text-white", style "margin-bottom" "0.3rem"] [text "Enter a roomCode"]
                   , viewInput "text" "Roomcode" (toLower model.roomCode) RoomCode
                   , button [class "button", onClick (Submit True) ] [ text "submit" ]
                   , p [] [ text model.response]
                   ],
              div [class "column is-one-fifth is-flex is-horizontal-center"]
                  [
                    img [src "/images/thalia.svg", class ""] []
                  ]
            ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg, class "input formField"] []


