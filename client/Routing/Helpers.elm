module Routing.Helpers exposing (internalHtmlLink, internalLink, locationToRoute, routeToUrl, testRoute)

import Dict
import Helpers.String exposing (parseUrl)
import Html exposing (Html, a, text)
import Html.Attributes exposing (class, href)
import Routing.Models
    exposing
        ( PageLoader
        , ParsedUrl
        , Route(..)
        , RouteConfig
        , routeToUrl
        , routingConfig
        )
import Url exposing (Url)


routeToUrl : Route -> String
routeToUrl =
    Routing.Models.routeToUrl


{-| Create Html link to internal page using Route type
-}
internalHtmlLink : Route -> List (Html msg) -> Html msg
internalHtmlLink route content =
    a
        [ class "dc-link"
        , href (routeToUrl route)
        ]
        content


internalLink : String -> Route -> Html msg
internalLink name route =
    internalHtmlLink route [ text name ]


locationToRoute : Url -> Route
locationToRoute location =
    let
        parsedUrl =
            location.fragment
                |> Maybe.withDefault ""
                |> parseUrl
    in
    routingConfig
        |> List.filterMap (testRoute parsedUrl)
        |> List.head
        |> Maybe.withDefault NotFoundRoute


{-| Match the parsed url against the url template and maybe return Constructed route type.
Example:
testRoute (["types","sales-event"],{"formatted":"true"} ) ("types/:name", makeRoute)
Returns:
Just EventTypesDetailsRoute {name: "sales-event"} {formatted: Just True, }
-}
testRoute : ParsedUrl -> RouteConfig -> Maybe Route
testRoute ( path, query ) ( pattern, toRoute ) =
    let
        -- Folds the template path to true/false collecting params on the way
        isMatch templateFolder matchResult =
            let
                fullStop =
                    { match = False, params = Dict.empty, rest = [] }

                next =
                    { matchResult | rest = List.drop 1 matchResult.rest }

                key =
                    String.dropLeft 1 templateFolder
            in
            case List.head matchResult.rest of
                Just folderName ->
                    if templateFolder |> String.startsWith ":" then
                        { next
                            | params = Dict.insert key folderName matchResult.params
                        }

                    else if folderName == templateFolder then
                        next

                    else
                        fullStop

                Nothing ->
                    fullStop

        result =
            pattern
                |> String.split "/"
                |> List.foldl isMatch
                    { params = Dict.empty
                    , match = True
                    , rest = path
                    }
    in
    if result.match && List.isEmpty result.rest then
        Just (toRoute ( result.params, query ))

    else
        Nothing
