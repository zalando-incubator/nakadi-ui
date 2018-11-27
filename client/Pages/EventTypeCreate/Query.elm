module Pages.EventTypeCreate.Query exposing (..)

import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Json.Encode as Json
import Http
import Config
import Helpers.Forms exposing (..)
import Helpers.AccessEditor as AccessEditor
import Stores.Authorization exposing (Authorization, emptyAuthorization)


{--------------- View -----------------}

import Html exposing (..)
import Html.Attributes exposing (..)
import Helpers.AccessEditor as AccessEditor
import Config
import Helpers.Forms exposing (..)
import Pages.EventTypeDetails.Help as Help
import Helpers.Panel
import Stores.EventType exposing (allAudiences)
import Models exposing (AppModel)
import Helpers.UI exposing (..)
import Helpers.Ace as Ace


viewQueryForm : AppModel -> Html Msg
viewQueryForm model =
    let
        formModel =
            model.eventTypeCreatePage

        { appsInfoUrl, usersInfoUrl, supportUrl } =
            model.userStore.user.settings

        formTitle =
            "Create SQL Query"
    in
        div [ class "dc-column form-create__form-container" ]
            [ div []
                [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
                , textInput formModel
                    FieldName
                    OnInput
                    "Output Event Type Name"
                    "Example: bazar.price-updater.price_changed"
                    "Should be several words (with '_', '-') separated by dot."
                    Help.eventType
                    Required
                    Enabled
                , textInput formModel
                    FieldOwningApplication
                    OnInput
                    "Owning Application"
                    "Example: stups_price-updater"
                    "App name registered in YourTurn with 'stups_' prefix"
                    Help.owningApplication
                    Required
                    Enabled
                , textInput formModel
                    FieldOrderingKeyFields
                    OnInput
                    "Ordering Key Fields"
                    "Example: order.day, order.index"
                    "Comma-separated list of keys."
                    Help.orderingKeyFields
                    Optional
                    Enabled
                , selectInput formModel
                    FieldAudience
                    OnInput
                    "Audience"
                    ""
                    Help.audience
                    Required
                    Enabled
                    ("" :: allAudiences)
                , sqlEditor formModel
                , hr [ class "dc-divider" ] []
                , sqlAccessEditor appsInfoUrl usersInfoUrl formModel
                ]
            , hr [ class "dc-divider" ]
                []
            , div
                [ class "dc-toast__content dc-toast__content--success" ]
                [ text "Nakady SQL Query Created!" ]
                |> Helpers.Panel.loadingStatus formModel
            , buttonPanel formTitle Submit Reset FieldName formModel
            ]


sqlEditor : Model -> Html Msg
sqlEditor formModel =
    inputFrame FieldSql "SQL Query" "" helpSql Required formModel <|
        div []
            [ div [ class "dc-btn-group" ] []
            , pre
                [ class "ace-edit" ]
                [ Ace.toHtml
                    [ Ace.value (getValue FieldSql formModel.values)
                    , Ace.onSourceChange (OnInput FieldSql)
                    , Ace.mode "sql"
                    , Ace.theme "dawn"
                    , Ace.tabSize 4
                    , Ace.useSoftTabs False
                    , Ace.extensions [ "language_tools" ]
                    , Ace.enableLiveAutocompletion True
                    , Ace.enableBasicAutocompletion True
                    ]
                    []
                ]
            ]


sqlAccessEditor : String -> String -> Model -> Html Msg
sqlAccessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , showWrite = False
        , showAnyToken = False
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor



{-------------- Update ----------------}


submitQueryCreate : Model -> Cmd Msg
submitQueryCreate model =
    let
        orderingKeyFields =
            model.values
                |> getValue FieldOrderingKeyFields
                |> stringToJsonList

        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        auth =
            AccessEditor.unflatten model.accessEditor.authorization
                |> Stores.Authorization.encoderReadAdmin

        fields =
            [ ( "output_event_type"
              , Json.object
                    [ ( "name", asString FieldName )
                    , ( "owning_application", asString FieldOwningApplication )
                    , ( "ordering_key_fields", orderingKeyFields )
                    , ( "audience", asString FieldAudience )
                    ]
              )
            , ( "sql", asString FieldSql )
            , ( "authorization", auth )
            ]

        body =
            Json.object (fields)
    in
        post body


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "queries"
        , body = Http.jsonBody body
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


stringToJsonList : String -> Json.Value
stringToJsonList str =
    str
        |> String.split ","
        |> List.map String.trim
        |> List.filter (String.isEmpty >> not)
        |> List.map Json.string
        |> Json.list


helpSql : List (Html msg)
helpSql =
    [ text "The SQL query to be run by the executor."
    , newline
    , text "The SQL statements supported are a subset of ANSI SQL."
    , newline
    , text "The operations supported are joining two or more EventTypes and filtering"
    , text " EventTypes to an output EventType. The EventTypes on which these queries are run MUST"
    , text " be log-compacted EventTypes. The EventTypes that are used for join queries MUST have the"
    , text " equal number of partitions and the EventTypes are joined on their compaction keys. Also,"
    , text " the join is done on per partition basis. The output EventType has the same number of"
    , text " partitions as the input EventType(s)."
    , newline
    , link "More in the API Manual" "https://apis.zalando.net/apis/3d932e38-b9db-42cf-84bb-0898a72895fb/ui"
    ]
