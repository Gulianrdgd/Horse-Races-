port module Game exposing (..)

import Browser
import Html exposing (Html, button, div, h1, img, li, p, text, ul)
import Html.Attributes exposing (class, src, style)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (decodeString, keyValuePairs, string, list)
import List exposing (head, length, reverse, take)
import Loading exposing (LoaderType(..), defaultConfig)
import Json.Encode as Encode
import String exposing (fromInt, toInt, uncons)
import Time as Time exposing (Posix)

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


raceLength : Int
raceLength = 6


cardFlipSpeed : Float
cardFlipSpeed = 5000


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
    | WaitCard


type alias RoundInfo =
  { username : String
  , roomCode : String
  , color : Color
  , bet: Int
  , winner: Color
  , state: State
  , isHost: Bool
  , url: String
  , race: Race
  , raceField: List (List (String))
  , winners: List(String, Int)
  }


type alias Race = {
    posH: Int
    , posS: Int
    , posC: Int
    , posD: Int
    , posFlip: Int
    }


init : String -> RoundInfo
init url =
  RoundInfo "" "" Empty 0 Empty Bet False url initRace (createRaceListP raceLength 0 ) []


initRace : Race
initRace = Race raceLength raceLength raceLength raceLength (raceLength - 1)


changeRace : Race -> Char -> Race
changeRace race el = case el of
                        'h' -> {race | posH = race.posH - 1}
                        's' -> {race | posS = race.posS - 1}
                        'c' -> {race | posC = race.posC - 1}
                        'd' -> {race | posD = race.posD - 1}
                        _  ->  race


subscriptions : RoundInfo -> Sub Msg
subscriptions model =
    if model.isHost && model.winner == Empty && model.state == Run then
        Sub.batch [ messageReceiver Recv, Time.every (cardFlipSpeed) (nextCardInRace model)]
    else messageReceiver Recv


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
  | Null (Cmd Msg)
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
    Null x -> (model, x)
    Recv "?isHost" ->   ({ model | isHost = True}, Cmd.none)
    Recv s -> case decode s of
                [("?username", user)] -> ({ model | username = user}, Cmd.none)
                [("?roomCode", roomCode)] -> ({ model | roomCode = roomCode}, Cmd.none)
                x -> case head x of
                  Just ("body", "?letsgo") -> ({ model | state = Run}, Cmd.none)
                  Just ("body", "?nextCard") ->
                    case model.state of
                        WaitCard -> -- CardFlip
                            case head ( reverse (take 2 x)) of
                                                        Just ("card", card) -> flipCard model card
                                                        _ -> (model , Cmd.none)
                        _ -> case head ( reverse (take 2 x)) of
                            Just ("card", card) -> changeCardPos model card
                            _ -> (model , Cmd.none)
                  _ -> let set = winnersTransform x in ({model | winners = set }, Cmd.none)


flipCard : RoundInfo -> String -> (RoundInfo, Cmd Msg)
flipCard model card = case uncons card of
                      Just (x, _) -> ({model |  raceField = ((model.raceField) |> List.indexedMap (\index field -> List.indexedMap (\id el -> if id == 0 && index == model.race.posFlip then (card ++ ".jpg") else el) field)),
                                                state = Run, race = penalty model.race x}, Cmd.none)
                      _ -> (model, Cmd.none)


penalty : Race -> Char -> Race
penalty race color = case color of
                        'h' -> {race | posH = race.posH + 1, posFlip = race.posFlip - 1}
                        'c' -> {race | posC = race.posC + 1, posFlip = race.posFlip - 1}
                        's' -> {race | posS = race.posS + 1, posFlip = race.posFlip - 1}
                        'd' -> {race | posD = race.posD + 1, posFlip = race.posFlip - 1}
                        _ -> race


changeCardPos : RoundInfo -> String -> (RoundInfo, Cmd Msg)
changeCardPos model card = case uncons card of
                            Just (x, _) -> let raceModel = changeRace model.race x in
                                   if raceModel.posH == 0 then
                                        ({model | race = raceModel, winner=H}, sendMessage (Encode.encode 0 (Encode.object [("message", Encode.string "?winner"), ("winner", Encode.string "H")])))
                                   else if raceModel.posS == 0 then
                                        ({model | race = raceModel, winner=S}, sendMessage (Encode.encode 0 (Encode.object [("message", Encode.string "?winner"), ("winner", Encode.string "S")])))
                                   else if raceModel.posC == 0 then
                                        ({model | race = raceModel, winner=C}, sendMessage (Encode.encode 0 (Encode.object [("message", Encode.string "?winner"), ("winner", Encode.string "C")])))
                                   else if raceModel.posD == 0 then
                                        ({model | race = raceModel, winner=D}, sendMessage (Encode.encode 0 (Encode.object [("message", Encode.string "?winner"), ("winner", Encode.string "D")])))
                                   else if model.race.posS <= model.race.posFlip && model.race.posH <= model.race.posFlip && model.race.posD <= model.race.posFlip && model.race.posC <= model.race.posFlip then
                                        ({model | state = WaitCard}, if model.isHost then Http.get {url = model.url ++ "/api/" ++  model.roomCode ++ "/cards/getCard", expect = Http.expectString Response } else Cmd.none)
                                   else
                                        ({model | race = raceModel}, Cmd.none)
                            _ -> (model, Cmd.none)


winnersTransform : List (String, String) -> List (String, Int)
winnersTransform list = List.map (\(user, val) -> (user, (toIntP val))) list


toIntP : String -> Int
toIntP s = case toInt s of
            Just val -> val
            _ -> -1


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
        else if model.state == Run || model.state == WaitCard then
              div [ class "container fade center"]
                  [
                  if model.winner /= Empty then
                        presentWinners model
                  else div [] [],
                      drawRace model
                  ]
        else
            div [class "container fade center", style "margin-top" "-5rem"]
            [
              h1 [class "title is-1 center fade has-text-white"] [text "Please select the amount of sips"],
              div  [class "container form fade center"]
                    [
                        h1 [class "title is-1" ,onClick Increment ] [text "🍺"],
                        h1 [class "title is-1  has-text-white"] [text (fromInt model.bet)],
                        h1 [class "title is-1 ", onClick Decrement ] [text "😥"],
                        button [class "button", onClick (Ready Waiting)] [text "Submit*"],
                        p [class "subtitle is-5 has-text-white footnote"] [text "*I hereby swear I will drink double my entered bet if I loose.\n Any lying participant will be reported"]
                    ]
            ]
    ]


presentWinners : RoundInfo -> Html msg
presentWinners model =
                     div [class "message is-large winnersBody center fade is-primary shadow", style "margin-top" "5rem"]
                     [
                     div [class "message-header center"]
                     [
                        h1 [class "title is-1 has-text-white center", style "margin" "auto" ] [text "The race has ended!"]
                     ],
                     div [class "message-body"]
                     [
                     case length model.winners of
                       0 ->
                           ul []
                           [
                                li [] [h1 [class "title is-1"] [text "Sadly, there are no winners!"]]
                           ]
                       _ ->
                            (model.winners)
                                |> List.map(\(username, val) -> li [] [h1 [class "title is-1"] [text (username ++ " can give out " ++ fromInt (val*2) ++ " sips!" )]])
                                |> ul []
                      ]
                    ]


drawRace : RoundInfo -> Html msg
drawRace model = (model.raceField)
                        |> List.indexedMap(\index list -> (List.indexedMap (\i el -> let card = checkIndex index i el model in if card == "" then
                                                li [style "display" "inline"] [img [src ("/images/" ++ "null.png"), class "cardRun hidden", style "visibility" "hidden"] []]
                                                else
                                                li [style "display" "inline"] [img [src ("/images/Cards/" ++ card), class "cardRun fade"] []]) list) |> ul [] )
                        |> ul [style "margin-top" "3rem", class "is-mobile"]


createRaceListP : Int -> Int -> List (List (String))
createRaceListP size pos = if (pos == size) then [["", "h14.jpg", "s14.jpg", "c14.jpg", "d14.jpg"]]
                           else [["back.jpg", "", "", "", ""]] ++ (createRaceListP size (pos+1))


checkIndex : Int -> Int -> String -> RoundInfo -> String
checkIndex index i el model = case i of
                         0 ->
                              if el /= "" && index /= raceLength && index /= 0 then
                                el
                              else if index /= raceLength && index /= 0 then
                                "back.jpg"
                              else
                                ""
                         1 -> if model.race.posH == index then
                            "h14.jpg"
                            else ""
                         2 -> if model.race.posS == index then
                            "s14.jpg"
                            else ""
                         3-> if model.race.posC == index then
                            "c14.jpg"
                            else ""
                         4 -> if model.race.posD == index then
                            "d14.jpg"
                            else ""
                         _ -> ""


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
                Err _ -> case decodeString (Json.Decode.list (Json.Decode.list (string))) json of
                            Ok val -> List.map jsonArr val
                            Err _ ->  [("no", "no")]


jsonArr : List String -> (String, String)
jsonArr lst = case head lst of
                Just user -> case head (reverse lst) of
                        Just val -> (user, val)
                        _ -> ("no", "no")
                _ -> ("no", "no")


nextCardInRace : RoundInfo -> Posix -> Msg
nextCardInRace model _ =
    let cmd = Http.get {url = model.url ++ "/api/" ++  model.roomCode ++ "/cards/getCard", expect = Http.expectString Response } in Null cmd