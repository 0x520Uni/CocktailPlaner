module Route exposing (fromUrl, toPath)

-- URL parsing and serialisation for the three top-level routes (ADR-0007).
-- fromUrl turns a browser URL into a Route; toPath turns a Route into an href string.

import Types exposing (Route(..))
import Url exposing (Url)
import Url.Parser exposing (Parser, map, oneOf, s, top)


-- Matches the three known URL paths to their Route values.
parser : Parser (Route -> a) a
parser =
    oneOf
        [ map HomeRoute top          -- "/"
        , map ShoppingRoute (s "shopping")  -- "/shopping"
        , map GlossarRoute (s "glossar")    -- "/glossar"
        ]


-- Parse a full URL into a Route. Falls back to HomeRoute for unknown paths.
fromUrl : Url -> Route
fromUrl url =
    Maybe.withDefault HomeRoute (Url.Parser.parse parser url)


-- Convert a Route to a URL path string, used in href attributes.
toPath : Route -> String
toPath route =
    case route of
        HomeRoute ->
            "/"

        ShoppingRoute ->
            "/shopping"

        GlossarRoute ->
            "/glossar"
