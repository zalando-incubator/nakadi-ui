module Stores.Query exposing (Model, Msg(..), Query, initialModel, memberDecoder, update)

import Config
import Constants
import Dict
import Helpers.Regex
import Helpers.Store as Store
import Helpers.Task exposing (dispatch)
import Http
import Json.Decode exposing (Decoder, at, bool, list, map, maybe, nullable, string, succeed)
import Json.Decode.Pipeline exposing (optional, required)
import Regex
import Stores.Authorization exposing (Authorization)
import User.Commands exposing (logoutIfExpired)


type alias Query =
    { id : String
    , sql : String
    , envelope : Bool
    , created : String
    , updated : String
    , read_from : String
    , authorization : Maybe Authorization
    , status : String
    }


type alias Page =
    { items : List Query
    , links : Links
    }


type alias Links =
    { next : Maybe String
    }


type alias Model =
    Store.Model Query


type Msg
    = FetchDone (Result Http.Error Page)
    | FetchData
    | OutFetchAllDone


initialModel : Model
initialModel =
    Store.initialModel


startUrl : String
startUrl =
    "/queries?limit=1000"


update : Msg -> Model -> ( Model, Cmd Msg )
update message store =
    case message of
        FetchData ->
            ( Store.onFetchStart initialModel, fetchNext startUrl )

        FetchDone (Ok page) ->
            let
                newStore =
                    addPageToStore store page.items
            in
            case page.links.next of
                Just url ->
                    ( newStore, fetchNext url )

                Nothing ->
                    ( Store.onFetchOk newStore, dispatch OutFetchAllDone )

        FetchDone (Err error) ->
            ( Store.onFetchErr store error, logoutIfExpired error )

        OutFetchAllDone ->
            ( store, Cmd.none )


addPageToStore : Model -> List Query -> Model
addPageToStore store list =
    let
        newDict =
            list
                |> List.map (\query -> ( query.id, query ))
                |> Dict.fromList
                |> Dict.union store.dict
    in
    { store | dict = newDict }



--
-- We proxy requests to Nakadi SQL API via our own backend, but the response
-- might contain the link to the next page with the hostname of the actual
-- API, instead of just the path.  The next request to fetch it may be blocked
-- by the browser's CORS policy, unless we replace the host before path with
-- our own.
--
-- Parsing the URL properly seems to be too involved, so we rely on a regex.
--


urlBeforePathRegex =
    Helpers.Regex.fromString "^(https?://[^/]+)?/"


fetchNext : String -> Cmd Msg
fetchNext next =
    let
        url =
            Regex.replace urlBeforePathRegex (\_ -> Config.urlNakadiSqlApi) next
    in
    Http.get url pageDecoder |> Http.send FetchDone



-- Decoders


pageDecoder : Decoder Page
pageDecoder =
    succeed Page
        |> required "items" (list memberDecoder)
        |> required "_links" linksDecoder


linksDecoder : Decoder Links
linksDecoder =
    map Links <| maybe (at [ "next", "href" ] string)


memberDecoder : Decoder Query
memberDecoder =
    succeed Query
        |> required Constants.id string
        |> required "sql" string
        |> required "envelope" bool
        |> required "created" string
        |> required "updated" string
        |> optional "read_from" string "end"
        |> optional "authorization" (nullable Stores.Authorization.collectionDecoder) Nothing
        |> required "status" string
