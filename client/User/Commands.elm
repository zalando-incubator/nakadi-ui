module User.Commands exposing (fetchAll, logout, logoutIfExpired, memberDecoder, settingsDecoder)

import Config
import Constants exposing (emptyString)
import Helpers.Http exposing (postString)
import Http exposing (Error(..))
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, optional, required)
import User.Messages exposing (Msg(..))
import User.Models exposing (Settings, User)


fetchAll : Cmd User.Messages.Msg
fetchAll =
    Http.send FetchAllDone <| Http.get Config.urlUser memberDecoder


memberDecoder : Decode.Decoder (Maybe User)
memberDecoder =
    decode User
        |> required Constants.id string
        |> required Constants.name string
        |> required "settings" settingsDecoder
        |> maybe


settingsDecoder : Decoder Settings
settingsDecoder =
    decode Settings
        |> required "nakadiApiUrl" string
        |> optional "appsInfoUrl" string emptyString
        |> optional "usersInfoUrl" string emptyString
        |> optional "monitoringUrl" string emptyString
        |> optional "sloMonitoringUrl" string emptyString
        |> optional "eventTypeMonitoringUrl" string emptyString
        |> optional "subscriptionMonitoringUrl" string emptyString
        |> optional "docsUrl" string emptyString
        |> optional "supportUrl" string emptyString
        |> optional "forbidDeleteUrl" string emptyString
        |> optional "allowDeleteEvenType" bool False
        |> optional "showNakadiSql" bool False
        |> optional "queryMonitoringUrl" string emptyString


{-| Redirect browser to logout
This function never actually returns
but to be a function in Elm it must accept some dummy argument
-}
logout : a -> Cmd msg
logout dummy =
    postString (\r -> Debug.crash "Logout performed") "elm:forceReLogin" Config.urlLogout


{-| Check the response from the server and if return is not recoverable
(like expired credentials) redirect browser to logout.
This way it's cleaning all cached data and redirects the user back to the login page.
Normally, invalid access token checked on Nakadi UI server and it sends code 401
But if proxy works with Nakadi directly (without checking the access token) then
Nakadi sends code 400 with the special body content
-}
logoutIfExpired : Http.Error -> Cmd msg
logoutIfExpired error =
    case error of
        BadStatus response ->
            case response.status.code of
                401 ->
                    logout "dummy"

                400 ->
                    if response.body |> String.contains "\"Access Token not valid\"" then
                        logout "dummy"

                    else
                        Cmd.none

                _ ->
                    Cmd.none

        _ ->
            Cmd.none
