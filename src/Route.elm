module Route exposing (fromUrl, parse, toPath)

-- URL parsing and serialisation for the three top-level routes (ADR-0007).
-- fromUrl turns a browser URL into a Route; toPath turns a Route into an href string.

import Types exposing (Route(..))
import Url exposing (Url)
import Url.Parser exposing (Parser, map, oneOf, s, top)



-- Matches the three known URL paths to their Route values.


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map HomeRoute top -- "/"
        , map ShoppingRoute (s "shopping") -- "/shopping"
        , map GlossarRoute (s "glossar") -- "/glossar"
        ]



-- Hash-based routing: the route lives in the URL fragment (after #), not the path.
-- The fragment is never sent to the server, so a reload or a shared link always loads
-- index.html and the route is resolved here on the client. We move the fragment into
-- the path field so the existing path parser above can match it unchanged.
-- Returns Nothing for an unknown route so callers can distinguish "real home" from
-- "bogus URL that fell through".


parse : Url -> Maybe Route
parse url =
    Url.Parser.parse parser
        { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }



-- Parse a full URL into a Route. Falls back to the Events home page for unknown routes.


fromUrl : Url -> Route
fromUrl url =
    Maybe.withDefault HomeRoute (parse url)



-- Convert a Route to a hash-fragment href string (e.g. "#/shopping"), used in links
-- and Nav.pushUrl. The leading "#" keeps navigation client-side and shareable.


toPath : Route -> String
toPath route =
    case route of
        HomeRoute ->
            "#/"

        ShoppingRoute ->
            "#/shopping"

        GlossarRoute ->
            "#/glossar"
