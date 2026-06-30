module View.Shopping exposing (view)

-- Shopping list page.
-- Reads the active event, aggregates ingredient amounts across all cocktails × portions,
-- and displays a table where the user can choose a package size per liquid ingredient.

import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, option, p, select, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, selected, style, value)
import Html.Events exposing (onClick, onInput)
import Types exposing (..)



-- LOCAL TYPE


-- One row in the shopping table: the summed amount of a single ingredient
-- after multiplying each cocktail's measure by its portion count.
type alias AggregatedIngredient =
    { name : String
    , amount : IngredientAmount
    }



-- PACKAGE SIZE PRESETS


-- The dropdown options offered to the user for liquid ingredients.
presets : List ( Float, String )
presets =
    [ ( 250, "250 ml" )
    , ( 330, "330 ml (Dose)" )
    , ( 500, "500 ml" )
    , ( 700, "700 ml (Standard)" )
    , ( 1000, "1000 ml (1 L)" )
    ]


-- Returns the currently selected package size for an ingredient.
-- Falls back to 700 ml (standard bottle) if the user has not chosen yet.
currentPackageSize : String -> Dict String Float -> Float
currentPackageSize name sizes =
    Dict.get name sizes |> Maybe.withDefault 700



-- MAIN VIEW


-- Entry point called by Main.view.
view : Model -> Html Msg
view model =
    div [ class "section" ]
        [ div [ class "container" ]
            [ h1 [ class "title" ] [ text "Einkaufsliste" ]
            , viewBody model
            ]
        ]


-- Decides what to render based on whether an event is open.
viewBody : Model -> Html Msg
viewBody model =
    case model.activeEventId of
        Nothing ->
            -- No event is open: ask the user to open one first.
            div [ class "notification is-info is-light" ]
                [ p [] [ text "Kein Event ausgewählt." ]
                , p [ style "margin-top" "0.5rem" ]
                    [ text "Öffne ein Event auf der Startseite, um die Einkaufsliste zu berechnen." ]
                , button
                    [ class "button is-primary mt-3"
                    , onClick (NavigateTo HomeRoute)
                    ]
                    [ text "Zur Startseite" ]
                ]

        Just eventId ->
            -- Find the event in the list (should always succeed if the ID is set correctly).
            case List.filter (\e -> e.id == eventId) model.events |> List.head of
                Nothing ->
                    div [ class "notification is-danger is-light" ]
                        [ text "Event nicht gefunden." ]

                Just event ->
                    viewEvent model event


-- Renders the full shopping view for a specific event.
viewEvent : Model -> Event -> Html Msg
viewEvent model event =
    let
        aggregated =
            computeTotals event model.cocktailCache
    in
    if List.isEmpty event.cocktails then
        div [ class "notification is-warning is-light" ]
            [ text ("Event \"" ++ event.name ++ "\" hat noch keine Cocktails.") ]

    else if List.isEmpty aggregated then
        -- Event has cocktails but none are in the cache yet (still loading).
        div [ class "notification is-warning is-light" ]
            [ text "Cocktaildaten werden noch geladen. Kurz warten und Seite neu laden." ]

    else
        div []
            [ p [ class "subtitle" ]
                [ text (event.name ++ " · " ++ String.fromInt event.guestCount ++ " Gäste") ]
            , table [ class "table is-fullwidth is-striped is-hoverable" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Zutat" ]
                        , th [] [ text "Gesamt" ]
                        , th [] [ text "Packungsgröße" ]
                        , th [] [ text "Kaufen" ]
                        ]
                    ]
                , tbody []
                    (List.map (viewRow model.packageSizes) aggregated)
                ]
            ]


-- Renders one table row for a single aggregated ingredient.
viewRow : Dict String Float -> AggregatedIngredient -> Html Msg
viewRow packageSizes agg =
    tr []
        [ td [] [ text agg.name ]
        , td [] [ text (formatGesamt agg.amount) ]
        , td [] [ viewPackageSizeCell agg.name agg.amount packageSizes ]
        , td [] [ text (formatKaufen agg.name agg.amount packageSizes) ]
        ]


-- Renders the "Packungsgröße" cell.
-- Liquids get a dropdown; other types get a dash.
viewPackageSizeCell : String -> IngredientAmount -> Dict String Float -> Html Msg
viewPackageSizeCell name amount packageSizes =
    case amount of
        LiquidMl _ ->
            let
                chosen =
                    currentPackageSize name packageSizes
            in
            div [ class "select is-small" ]
                [ select
                    [ onInput
                        (\s ->
                            case String.toFloat s of
                                Just size ->
                                    SetPackageSize name size

                                Nothing ->
                                    -- Ignore non-numeric input; keep the current value.
                                    SetPackageSize name chosen
                        )
                    ]
                    (List.map
                        (\( size, label ) ->
                            option
                                [ value (String.fromFloat size)
                                , selected (size == chosen)
                                ]
                                [ text label ]
                        )
                        presets
                    )
                ]

        _ ->
            span [] [ text "—" ]



-- FORMATTING HELPERS


-- Formats the "Gesamt" (total needed) column value.
formatGesamt : IngredientAmount -> String
formatGesamt amount =
    case amount of
        LiquidMl ml ->
            String.fromInt (round ml) ++ " ml"

        PieceCount n ->
            "× " ++ String.fromInt (round n)

        UnknownAmount ->
            "—"


-- Calculates and formats the "Kaufen" (buy) column value.
-- For liquids: ceiling(total / packageSize) packages.
-- For pieces: repeat the count. For unknown: "nach Bedarf".
formatKaufen : String -> IngredientAmount -> Dict String Float -> String
formatKaufen name amount packageSizes =
    case amount of
        LiquidMl ml ->
            let
                packageSize =
                    currentPackageSize name packageSizes

                needed =
                    ceiling (ml / packageSize)
            in
            if needed == 1 then
                "1 Fl."

            else
                String.fromInt needed ++ " Fl."

        PieceCount n ->
            "× " ++ String.fromInt (round n)

        UnknownAmount ->
            "nach Bedarf"



-- AGGREGATION


-- Computes the total amount of each ingredient across all cocktails in the event.
-- For each EventCocktail: look up the full cocktail, multiply each ingredient's
-- amount by portions, then sum across all cocktails grouped by ingredient name.
-- Ingredients missing from the cache (not loaded yet) are silently skipped.
computeTotals : Event -> Dict String FullCocktail -> List AggregatedIngredient
computeTotals event cache =
    let
        -- Expand every event cocktail into a flat list of (name, scaled-amount) pairs.
        allPairs : List ( String, IngredientAmount )
        allPairs =
            List.concatMap
                (\ec ->
                    case Dict.get ec.cocktailId cache of
                        Nothing ->
                            []

                        Just cocktail ->
                            List.map
                                -- Multiply portions by guestCount so the shopping list
                                -- scales with the number of guests (Fix for bug #3).
                                (\ing -> ( ing.name, scaleAmount (ec.portions * event.guestCount) ing.amount ))
                                cocktail.ingredients
                )
                event.cocktails

        -- Fold the flat list into a Dict, summing amounts for the same ingredient name.
        grouped : Dict String IngredientAmount
        grouped =
            List.foldl
                (\( name, amount ) acc ->
                    case Dict.get name acc of
                        Nothing ->
                            Dict.insert name amount acc

                        Just existing ->
                            Dict.insert name (addAmounts existing amount) acc
                )
                Dict.empty
                allPairs
    in
    -- Convert to a list and sort: liquids first, then pieces, then unknown, each group alphabetically.
    Dict.toList grouped
        |> List.map (\( name, amount ) -> { name = name, amount = amount })
        |> List.sortWith compareIngredients


-- Multiplies an ingredient amount by the number of portions.
scaleAmount : Int -> IngredientAmount -> IngredientAmount
scaleAmount portions amount =
    let
        factor =
            toFloat portions
    in
    case amount of
        LiquidMl ml ->
            LiquidMl (factor * ml)

        PieceCount n ->
            PieceCount (factor * n)

        UnknownAmount ->
            UnknownAmount


-- Adds two amounts of the same kind together.
-- If the kinds differ (e.g. one cocktail has "1 oz" and another has "3 pieces"),
-- we cannot sum them meaningfully and return UnknownAmount.
addAmounts : IngredientAmount -> IngredientAmount -> IngredientAmount
addAmounts a b =
    case ( a, b ) of
        ( LiquidMl x, LiquidMl y ) ->
            LiquidMl (x + y)

        ( PieceCount x, PieceCount y ) ->
            PieceCount (x + y)

        _ ->
            UnknownAmount


-- Sort order: LiquidMl < PieceCount < UnknownAmount, then alphabetically within each group.
compareIngredients : AggregatedIngredient -> AggregatedIngredient -> Order
compareIngredients a b =
    case ( a.amount, b.amount ) of
        ( LiquidMl _, LiquidMl _ ) ->
            compare a.name b.name

        ( LiquidMl _, _ ) ->
            LT

        ( _, LiquidMl _ ) ->
            GT

        ( PieceCount _, PieceCount _ ) ->
            compare a.name b.name

        ( PieceCount _, _ ) ->
            LT

        ( _, PieceCount _ ) ->
            GT

        _ ->
            compare a.name b.name
