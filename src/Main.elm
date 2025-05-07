port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, disabled, placeholder, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Pipeline



-- MODEL


type alias Todo =
    { id : String
    , content : String
    }


type alias Model =
    { todos : List Todo
    , newTodo : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { todos = [], newTodo = "" }
    , getTodos ()
    )



-- MESSAGES


type Msg
    = GotTodos (List Todo)
    | NewTodoCreated Todo
    | NewTodoInput String
    | RemoveTodo String
    | TodoDeleted String
    | SubmitTodo



-- PORTS


port getTodos : () -> Cmd msg


port createTodo : String -> Cmd msg


port removeTodo : String -> Cmd msg


port receiveTodos : (Decode.Value -> msg) -> Sub msg


port newTodoCreated : (Decode.Value -> msg) -> Sub msg


port todoDeleted : (String -> msg) -> Sub msg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTodos list ->
            ( { model | todos = list }, Cmd.none )

        NewTodoCreated todo ->
            ( { model | todos = model.todos ++ [ todo ] }, Cmd.none )

        NewTodoInput str ->
            ( { model | newTodo = str }, Cmd.none )

        RemoveTodo id ->
            ( model, removeTodo id )

        TodoDeleted id ->
            ( { model | todos = List.filter (\t -> t.id /= id) model.todos }, Cmd.none )

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
    div []
        [ fieldset [ class "fieldset" ]
            [ label []
                [ input
                    [ placeholder "What needs doing?"
                    , value model.newTodo
                    , onInput NewTodoInput
                    ]
                    []
                ]
            , button
                [ onClick SubmitTodo
                , disabled (String.trim model.newTodo == "")
                ]
                [ text "Add" ]
            ]
        , ul [] (List.map viewTodo model.todos)
        ]


viewTodo : Todo -> Html Msg
viewTodo todo =
    li []
        [ button [ onClick (RemoveTodo todo.id) ] [ text "Remove" ]
        , text (" " ++ todo.content)
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ receiveTodos
            (\value ->
                case Decode.decodeValue (Decode.list todoDecoder) value of
                    Ok list ->
                        GotTodos list

                    Err _ ->
                        GotTodos []
            )
        , newTodoCreated
            (\value ->
                case Decode.decodeValue todoDecoder value of
                    Ok todo ->
                        NewTodoCreated todo

                    Err _ ->
                        GotTodos []
            )
        , todoDeleted TodoDeleted
        ]


todoDecoder : Decoder Todo
todoDecoder =
    Decode.succeed Todo
        |> Pipeline.required "id" Decode.string
        |> Pipeline.required "content" Decode.string



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
