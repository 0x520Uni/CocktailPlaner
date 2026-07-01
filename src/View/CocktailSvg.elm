module View.CocktailSvg exposing (ingredientColors, view)

-- SVG measuring cup that shows cocktail ingredient proportions as stacked layers.
-- The layers are sized by the ingredient's measured amount (not ml — just relative ratios).
-- Ordering: first ingredient at the bottom, last at the top (as listed in the recipe).

import Svg exposing (Svg, clipPath, defs, g, rect, svg, text, text_)
import Svg.Attributes as A
import Types exposing (Ingredient, Msg)



-- CONSTANTS
-- Glass dimensions inside the SVG viewBox.


glassX : Float
glassX =
    20


glassY : Float
glassY =
    20


glassWidth : Float
glassWidth =
    120


glassHeight : Float
glassHeight =
    200



-- Colours assigned to ingredients in order. Cycles if there are more than 10.


palette : List String
palette =
    [ "#FF6B6B"
    , "#4ECDC4"
    , "#45B7D1"
    , "#FFEAA7"
    , "#DDA0DD"
    , "#96CEB4"
    , "#F0A500"
    , "#BB8FCE"
    , "#82E0AA"
    , "#F1948A"
    ]



-- PUBLIC API
-- Renders a measuring cup SVG for the given ingredient list.
-- Width/height are passed so the caller can control layout.


view : List Ingredient -> Svg Msg
view ingredients =
    let
        amounts =
            List.map (\i -> parseMeasure i.measure) ingredients

        total =
            List.sum amounts
                -- Guard against division by zero when all measures are unparsable.
                |> (\t ->
                        if t == 0 then
                            toFloat (List.length ingredients)

                        else
                            t
                   )

        -- Normalised amount in range [0, 1] for each ingredient.
        ratios =
            List.map (\a -> a / total) amounts

        -- Zip ingredients with their ratio and a colour from the palette.
        triples =
            List.map3
                (\ingredient ratio colour -> ( ingredient, ratio, colour ))
                ingredients
                ratios
                (cyclePalette (List.length ingredients))
    in
    svg
        [ A.viewBox "0 0 160 240"
        , A.style "height: 100%; width: auto; max-width: 100%; display: block;"
        ]
        [ defs []
            [ clipPath [ A.id "glass-clip" ]
                [ rect
                    [ A.x (String.fromFloat glassX)
                    , A.y (String.fromFloat glassY)
                    , A.width (String.fromFloat glassWidth)
                    , A.height (String.fromFloat glassHeight)
                    , A.rx "6"
                    ]
                    []
                ]
            ]

        -- Ingredient layers, clipped to the glass rectangle.
        , g [ A.clipPath "url(#glass-clip)" ]
            (renderLayers triples)

        -- Glass border on top so it sits above the colours.
        , rect
            [ A.x (String.fromFloat glassX)
            , A.y (String.fromFloat glassY)
            , A.width (String.fromFloat glassWidth)
            , A.height (String.fromFloat glassHeight)
            , A.rx "6"
            , A.fill "none"
            , A.stroke "#444444"
            , A.strokeWidth "2.5"
            ]
            []
        ]



-- LAYER RENDERING
-- Converts the list of (ingredient, ratio, colour) triples into a list of SVG rects.
-- The first ingredient sits at the BOTTOM of the glass, the last at the TOP,
-- so we reverse the list before computing cumulative heights.


renderLayers : List ( Ingredient, Float, String ) -> List (Svg Msg)
renderLayers triples =
    let
        -- Reverse so we build from bottom up (bottom = first ingredient).
        reversed =
            List.reverse triples

        -- Walk the reversed list accumulating the Y offset from the glass bottom.
        go remaining yFromBottom acc =
            case remaining of
                [] ->
                    acc

                ( ingredient, ratio, colour ) :: rest ->
                    let
                        layerHeight =
                            ratio * glassHeight

                        -- Y position: glass bottom minus everything accumulated so far.
                        yTop =
                            glassY + glassHeight - yFromBottom - layerHeight

                        layerRect =
                            rect
                                [ A.x (String.fromFloat glassX)
                                , A.y (String.fromFloat yTop)
                                , A.width (String.fromFloat glassWidth)
                                , A.height (String.fromFloat layerHeight)
                                , A.fill colour
                                ]
                                []

                        -- Centre of the band; both labels are anchored to it.
                        centerX =
                            glassX + glassWidth / 2

                        centerY =
                            yTop + layerHeight / 2

                        -- The computed share of the glass, shown so the viewer can see the
                        -- heights are calculated from the recipe data (not drawn by hand).
                        percentLabel =
                            String.fromInt (round (ratio * 100)) ++ "%"

                        -- Tall bands show name + percentage; medium bands only the name;
                        -- tiny bands stay empty so the glass does not get cluttered.
                        labelNodes =
                            if layerHeight >= 28 then
                                [ bandText centerX (centerY - 2) 10 "rgba(0,0,0,0.8)" ingredient.name
                                , bandText centerX (centerY + 11) 8 "rgba(0,0,0,0.55)" percentLabel
                                ]

                            else if layerHeight >= 18 then
                                [ bandText centerX (centerY + 4) 10 "rgba(0,0,0,0.75)" ingredient.name ]

                            else
                                []
                    in
                    go rest (yFromBottom + layerHeight) (acc ++ [ layerRect ] ++ labelNodes)
    in
    go reversed 0 []



-- HELPERS
-- One centred text label inside a band, reused for the ingredient name and the
-- percentage so both share the same anchoring and font family.


bandText : Float -> Float -> Int -> String -> String -> Svg Msg
bandText cx cy size colour content =
    text_
        [ A.x (String.fromFloat cx)
        , A.y (String.fromFloat cy)
        , A.textAnchor "middle"
        , A.fontSize (String.fromInt size)
        , A.fill colour
        , A.fontFamily "sans-serif"
        ]
        [ text content ]



-- Returns the list of colours assigned to n ingredients (same order as the SVG layers).
-- Call this from outside the module to match ingredient tags to SVG band colours.


ingredientColors : Int -> List String
ingredientColors n =
    cyclePalette n



-- Takes n colours from the palette, cycling if n > length of palette.


cyclePalette : Int -> List String
cyclePalette n =
    let
        len =
            List.length palette

        indices =
            List.range 0 (n - 1)
    in
    List.filterMap
        (\i ->
            -- elm/core has no List.getAt; simulate with drop + head.
            List.head (List.drop (modBy len i) palette)
        )
        indices



-- Parses a measure string like "1 1/2 oz" or "2 shots" into a Float.
-- Only the numeric part matters — units are irrelevant for ratios.
-- Returns 1.0 when nothing parsable is found.


parseMeasure : String -> Float
parseMeasure raw =
    let
        words =
            String.words raw
    in
    case words of
        [] ->
            1.0

        first :: rest ->
            case parseToken first of
                Just n ->
                    -- Check if the next word is a fraction like "1/2".
                    case rest of
                        next :: _ ->
                            case parseFraction next of
                                Just f ->
                                    n + f

                                Nothing ->
                                    n

                        [] ->
                            n

                Nothing ->
                    1.0



-- Parses a single token: plain integer, decimal, fraction "3/4", or range "6-8".


parseToken : String -> Maybe Float
parseToken rawToken =
    let
        -- For a range like "6-8" the API gives a span; we use the lower bound (6).
        -- Splitting on "-" and keeping the first part turns "6-8" into "6" and
        -- leaves a plain "2" untouched.
        token =
            case String.split "-" rawToken of
                lower :: _ :: _ ->
                    lower

                _ ->
                    rawToken
    in
    case String.split "/" token of
        [ num ] ->
            String.toFloat num

        [ num, den ] ->
            Maybe.map2 (/) (String.toFloat num) (String.toFloat den)

        _ ->
            Nothing



-- Only parses slash-fractions like "1/2".


parseFraction : String -> Maybe Float
parseFraction s =
    case String.split "/" s of
        [ num, den ] ->
            Maybe.map2 (/) (String.toFloat num) (String.toFloat den)

        _ ->
            Nothing
