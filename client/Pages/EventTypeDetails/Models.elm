module Pages.EventTypeDetails.Models exposing (..)

import Helpers.String exposing (justOrCrash, getMaybeBool, queryMaybeToUrl)
import Dict exposing (get)
import Helpers.JsonEditor as JsonEditor
import Constants exposing (emptyString)
import Stores.Publisher
import Stores.Consumer
import Stores.Partition
import Stores.CursorDistance
import Stores.EventTypeSchema
import Stores.EventTypeValidation
import Stores.Query exposing (Query)
import Helpers.Store exposing (Status(Unknown), ErrorMessage)
import RemoteData exposing (WebData, RemoteData(NotAsked))
import Pages.EventTypeDetails.PublishTab


initialModel : Model
initialModel =
    { formatted = True
    , effective = False
    , tab = SchemaTab
    , name = emptyString
    , version = Nothing
    , jsonEditor = JsonEditor.initialModel
    , publishersStore = Stores.Publisher.initialModel
    , consumersStore = Stores.Consumer.initialModel
    , partitionsStore = Stores.Partition.initialModel
    , eventTypeSchemasStore = Stores.EventTypeSchema.initialModel
    , totalsStore = Stores.CursorDistance.initialModel
    , validationIssuesStore = Stores.EventTypeValidation.initialModel
    , loadQueryResponse = NotAsked
    , deletePopup =
        { isOpen = False
        , deleteCheckbox = False
        , status = Unknown
        , error = Nothing
        }
    , deleteQueryPopupOpen = False
    , deleteQueryPopupCheck = False
    , deleteQueryResponse = NotAsked
    , publishTab = Pages.EventTypeDetails.PublishTab.initialModel
    }


type Tabs
    = SchemaTab
    | PartitionsTab
    | PublisherTab
    | ConsumerTab
    | AuthTab
    | PublishTab
    | QueryTab


type alias Model =
    { formatted : Bool
    , effective : Bool
    , tab : Tabs
    , name : String
    , version : Maybe String
    , jsonEditor : JsonEditor.Model
    , publishersStore : Stores.Publisher.Model
    , consumersStore : Stores.Consumer.Model
    , partitionsStore : Stores.Partition.Model
    , eventTypeSchemasStore : Stores.EventTypeSchema.Model
    , totalsStore : Stores.CursorDistance.Model
    , validationIssuesStore : Stores.EventTypeValidation.Model
    , loadQueryResponse : WebData Query
    , deletePopup :
        { isOpen : Bool
        , deleteCheckbox : Bool
        , status : Status
        , error : Maybe ErrorMessage
        }
    , deleteQueryPopupOpen : Bool
    , deleteQueryPopupCheck : Bool
    , deleteQueryResponse : WebData ()
    , publishTab : Pages.EventTypeDetails.PublishTab.Model
    }


type alias UrlParams =
    { name : String
    }


type alias UrlQuery =
    { formatted : Maybe Bool
    , effective : Maybe Bool
    , tab : Maybe Tabs
    , version : Maybe String
    }


dictToQuery : Dict.Dict String String -> UrlQuery
dictToQuery dict =
    { formatted =
        getMaybeBool "formatted" dict
    , effective =
        getMaybeBool "effective" dict
    , tab =
        get "tab" dict |> Maybe.andThen stringToTabs
    , version = get "version" dict
    }


emptyQuery : UrlQuery
emptyQuery =
    dictToQuery Dict.empty


queryToUrl : UrlQuery -> String
queryToUrl query =
    queryMaybeToUrl <|
        Dict.fromList
            [ ( "formatted", query.formatted |> Maybe.map toString )
            , ( "effective", query.effective |> Maybe.map toString )
            , ( "tab", query.tab |> Maybe.map toString )
            , ( "version", query.version )
            ]


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { name =
        get Constants.name dict |> justOrCrash "Incorrect url template. Missing /:name/"
    }


stringToTabs : String -> Maybe Tabs
stringToTabs str =
    case str of
        "SchemaTab" ->
            Just SchemaTab

        "PartitionsTab" ->
            Just PartitionsTab

        "PublisherTab" ->
            Just PublisherTab

        "ConsumerTab" ->
            Just ConsumerTab

        "AuthTab" ->
            Just AuthTab

        "PublishTab" ->
            Just PublishTab

        "QueryTab" ->
            Just QueryTab

        _ ->
            Nothing
