module Pages.QueryDetails.Models exposing (Model, Tabs(..), UrlParams, UrlQuery, dictToParams, dictToQuery, emptyQuery, initialModel, queryToUrl, stringToTabs)

import Constants exposing (emptyString)
import Dict exposing (get)
import Helpers.String exposing (justOrCrash, queryMaybeToUrl)
import RemoteData exposing (RemoteData(..), WebData)
import Stores.Query exposing (Query)


type Tabs
    = QueryTab
    | AuthTab


type alias Model =
    { name : String
    , loadQueryResponse : WebData Query
    , deleteQueryPopupOpen : Bool
    , deleteQueryPopupCheck : Bool
    , deleteQueryResponse : WebData ()
    }


initialModel : Model
initialModel =
    { name = emptyString
    , loadQueryResponse = NotAsked
    , deleteQueryPopupOpen = False
    , deleteQueryPopupCheck = False
    , deleteQueryResponse = NotAsked
    }


type alias UrlParams =
    { name : String
    }


type alias UrlQuery =
    { tab : Maybe Tabs
    }


dictToQuery : Dict.Dict String String -> UrlQuery
dictToQuery dict =
    { tab =
        get "tab" dict |> Maybe.andThen stringToTabs
    }


emptyQuery : UrlQuery
emptyQuery =
    dictToQuery Dict.empty


queryToUrl : UrlQuery -> String
queryToUrl query =
    queryMaybeToUrl <|
        Dict.fromList
            [ ( "tab", query.tab |> Maybe.map Debug.toString )
            ]


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { name =
        get Constants.name dict |> justOrCrash "Incorrect url template. Missing /:name/"
    }


stringToTabs : String -> Maybe Tabs
stringToTabs str =
    case str of
        "QueryTab" ->
            Just QueryTab

        "AuthTab" ->
            Just AuthTab

        _ ->
            Nothing
