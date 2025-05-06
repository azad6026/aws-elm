port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (disabled, placeholder, style, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode



-- MODEL


type alias Model =
    { todos : List String
    , newTodo : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { todos = [], newTodo = "" }
    , getTodos ()
    )



-- MESSAGES


type Msg
    = GotTodos (List String)
    | NewTodoCreated String
    | NewTodoInput String
    | SubmitTodo



-- PORTS


port getTodos : () -> Cmd msg


port createTodo : String -> Cmd msg


port receiveTodos : (Decode.Value -> msg) -> Sub msg


port newTodoCreated : (String -> msg) -> Sub msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTodos list ->
            ( { model | todos = list }, Cmd.none )

        NewTodoCreated item ->
            ( { model | todos = model.todos ++ [ item ] }, Cmd.none )

        NewTodoInput str ->
            ( { model | newTodo = str }, Cmd.none )

        SubmitTodo ->
            if String.trim model.newTodo == "" then
                ( model, Cmd.none )

            else
                ( { model | newTodo = "" }
                , createTodo model.newTodo
                )



-- VIEW


view : Model -> Html Msg
view model =
    div [ style "max-width" "400px", style "margin" "2rem auto" ]
        [ div [ style "display" "flex", style "gap" "0.5rem" ]
            [ input
                [ placeholder "What needs doing?"
                , value model.newTodo
                , onInput NewTodoInput
                ]
                []
            , button
                [ onClick SubmitTodo
                , disabled (String.trim model.newTodo == "")
                ]
                [ text "Add" ]
            ]
        , ul [] (List.map (\t -> li [] [ text t ]) model.todos)
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveTodos
            (\value ->
                case Decode.decodeValue (Decode.list Decode.string) value of
                    Ok list ->
                        GotTodos list

                    Err _ ->
                        GotTodos []
            )
        , newTodoCreated NewTodoCreated
        ]



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
