port module Game exposing (..)

import Browser
import Debug exposing (toString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http

-- MAIN

main : Program { url : String } RoundInfo Msg
main =
  Browser.element { init = \{ url } -> ( init url, Cmd.none ), update = update, subscriptions = subscriptions, view = view }


-- MODEL
port sendMessage : String -> Cmd msg
port messageReceiver : (String -> msg) -> Sub msg

type Color
    = H
    | S
    | C
    | D
    | Empty

type State
    = Waiting
    | Bet

type alias RoundInfo =
  { username : String
  , color : Color
  , bet: Int
  , winner: Color
  , state: State
  }


init : String -> RoundInfo
init str =
  RoundInfo "" Empty 0 Empty Bet

--url : String
--url = "http://localhost:4000/"

subscriptions : RoundInfo -> Sub Msg
subscriptions model =
  Sub.none

type Msg
  = Betting RoundInfo
  | Finish RoundInfo
  | Started Bool
  | Increment
  | Decrement
  | Ready State
  | Response (Result Http.Error String)


update : Msg -> RoundInfo -> ( RoundInfo, Cmd Msg )
update msg model =
  case msg of
    Betting info ->
         ({ model | color = info.color}, Cmd.none)
    Finish info ->
         ({ model | winner = info.winner}, Cmd.none)
    Started _ -> (model, Cmd.none)
    Response _ -> (model, Cmd.none)
    Ready x -> ({ model | state = x}, Cmd.none)
    Increment -> ({model | bet = model.bet + 1}, Cmd.none)
    Decrement -> case model.bet of
                    0 -> (model, Cmd.none)
                    a -> ({model | bet = a - 1}, Cmd.none)

view : RoundInfo -> Html Msg
view model =
    div [class "container fade"] [
        if model.color == Empty then
            div [ class "container fade"]
                       [
                        h1 [class "title is-1 center has-text-white"] [text "Please choose a card!"],
                        div [class "container columns is-mobile"]
                          [
                            div [class "column"]
                                [
                                    img [src "/images/Cards/s14.jpg", class "playingCard", onClick (Betting {model | color= S})] []
                                ],
                            div [class "column"]
                                [
                                    img [src "/images/Cards/d14.jpg", class "playingCard",  onClick (Betting {model | color= D})] []
                                ],
                            div [class "column"]
                                [
                                    img [src "/images/Cards/h14.jpg", class "playingCard",  onClick (Betting {model | color= H})] []
                                ],
                            div [class "column"]
                                [
                                    img [src "/images/Cards/c14.jpg", class "playingCard",  onClick (Betting {model | color= C})] []
                                ]
                          ]
                       ]
        else
            div [class "container fade center"]
            [
              h1 [class "title is-1 center fade has-text-white"] [text "Please select the amount of sips"],
              div  [class "container form fade center"]
                    [
                        h1 [class "title is-1" ,onClick Increment ] [text "🍺"],
                        h1 [class "title is-1  has-text-white"] [text (toString model.bet)],
                        h1 [class "title is-1 ", onClick Decrement ] [text "😥"],
                        button [class "button", onClick (Ready Waiting)] [text "Submit*"],
                        p [class "subtitle is-5 has-text-white footnote"] [text "*I hereby swear I will drink double my entered bet if I loose.\n Any lying participant will be reported"]
                    ]
            ]
    ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg, class "input formField"] []


