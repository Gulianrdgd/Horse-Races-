port module Game exposing (..)

import Browser
import Debug exposing (toString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (decodeString, keyValuePairs, string)
import List exposing (head)
import Loading exposing (LoaderType(..), defaultConfig)
import Json.Encode as Encode

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

colorString : Color -> String
colorString col = case col of
                    H -> "H"
                    S -> "S"
                    C -> "C"
                    D -> "D"
                    Empty -> "Empty"

type State
    = Waiting
    | Bet
    | Run

type alias RoundInfo =
  { username : String
  , color : Color
  , bet: Int
  , winner: Color
  , state: State
  , isHost: Bool
  , url: String
  }

type alias Race = {
    posH: Int
    , posS: Int
    , posC: Int
    , posD: Int
    , size: Int
    }



init : String -> RoundInfo
init url =
  RoundInfo "" Empty 0 Empty Bet False url

subscriptions : RoundInfo -> Sub Msg
subscriptions model =
  messageReceiver Recv

type Msg
  = Betting RoundInfo
  | Finish RoundInfo
  | Username String
  | Started Bool
  | Increment
  | Decrement
  | Ready State
  | IsHost Bool
  | Recv String
  | Response (Result Http.Error String)


update : Msg -> RoundInfo -> ( RoundInfo, Cmd Msg )
update msg model =
  case msg of
    Betting info ->
         ({ model | color = info.color}, Cmd.none)
    Finish info ->
         ({ model | winner = info.winner}, Cmd.none)
    Username user ->
         ({ model | username = user}, Cmd.none)
    Started _ -> (model, Cmd.none)
    Response _ -> (model, Cmd.none)
    Ready x -> ({ model | state = x}, sendMessage (Encode.encode 0 (sendBet model)))
    Increment -> ({model | bet = model.bet + 1}, Cmd.none)
    Decrement -> case model.bet of
                    0 -> (model, Cmd.none)
                    a -> ({model | bet = a - 1}, Cmd.none)
    IsHost x -> ({ model | isHost = x}, Cmd.none)
    Recv "?isHost" ->   ({ model | isHost = True}, Cmd.none)
    Recv s -> case decode s of
                [("username", user)] -> ({ model | username = user}, Cmd.none)
                x -> case head x of
                  Just ("body", "?letsgo") -> ({ model | state = Run}, Cmd.none)
                  _ -> (model , Cmd.none)

view : RoundInfo -> Html Msg
view model =
    div [class "container fade"] [
        if model.color == Empty && model.state /= Waiting then
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
        else if model.state == Waiting then
           div [ class "container fade center", style "margin-top" "-5rem"]
               [
                   p [class "title is-1 has-text-white fade center"] [text "Thank you! Please wait, some people are still betting..."],
                   div [class "container fade center"]
                   [
                       Loading.render
                       DoubleBounce -- LoaderType
                       { defaultConfig | color = "#FFF" } -- Config
                       Loading.On -- LoadingState
                   ]
               ]
        else
            div [class "container fade center", style "margin-top" "-5rem"]
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

sendBet : RoundInfo -> Encode.Value
sendBet info = Encode.object
        [ ("message",Encode.string "?bet")
        , ( "username", Encode.string info.username )
        , ( "color", Encode.string (colorString info.color))
        , ( "bet", Encode.int info.bet)
        ]

decode : String  -> List(String, String)
decode json = case decodeString (keyValuePairs string) json of
                Ok x -> x
                Err _ -> [("No JSON","No JSON")]

