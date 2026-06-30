module Codec exposing (SavedState, encodeToString, parseState)

-- JSON serialisation for the saveable part of the application state.
-- Only user-created data is persisted: events, the ID counter, and package sizes.
-- API cache (cocktailCache, categories) and UI state (route, dialog, etc.) are NOT saved
-- because the cache is re-fetched from TheCocktailDB and UI state resets on load anyway.

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Types exposing (Event, EventCocktail, IngredientAmount(..), Model)


-- The subset of Model that gets saved and restored.
type alias SavedState =
    { events : List Event
    , nextEventId : Int
    , packageSizes : Dict String Float
    }


-- Converts the current model into a pretty-printed JSON string.
-- Called in the Save dialog view to populate the textarea.
encodeToString : Model -> String
encodeToString model =
    E.encode 2 (encodeState model)


-- Parses a JSON string back into a SavedState.
-- Returns Err with a human-readable message if the JSON is invalid.
parseState : String -> Result String SavedState
parseState json =
    case D.decodeString stateDecoder json of
        Ok state ->
            Ok state

        Err err ->
            Err ("Ungültiges Format: " ++ D.errorToString err)



-- ENCODER


encodeState : Model -> E.Value
encodeState model =
    E.object
        [ ( "events", E.list encodeEvent model.events )
        , ( "nextEventId", E.int model.nextEventId )
        , ( "packageSizes", encodeDict model.packageSizes )
        ]


encodeEvent : Event -> E.Value
encodeEvent event =
    E.object
        [ ( "id", E.string event.id )
        , ( "name", E.string event.name )
        , ( "guestCount", E.int event.guestCount )
        , ( "cocktails", E.list encodeEventCocktail event.cocktails )
        ]


encodeEventCocktail : EventCocktail -> E.Value
encodeEventCocktail ec =
    E.object
        [ ( "cocktailId", E.string ec.cocktailId )
        , ( "portions", E.int ec.portions )
        ]


-- Dict String Float has no built-in encoder; we convert to a list of [key, value] pairs.
encodeDict : Dict String Float -> E.Value
encodeDict dict =
    dict
        |> Dict.toList
        |> List.map (\( k, v ) -> E.list identity [ E.string k, E.float v ])
        |> E.list identity



-- DECODER


stateDecoder : D.Decoder SavedState
stateDecoder =
    D.map3 SavedState
        (D.field "events" (D.list eventDecoder))
        (D.field "nextEventId" D.int)
        (D.field "packageSizes" dictDecoder)


eventDecoder : D.Decoder Event
eventDecoder =
    D.map4 Event
        (D.field "id" D.string)
        (D.field "name" D.string)
        (D.field "guestCount" D.int)
        (D.field "cocktails" (D.list eventCocktailDecoder))


eventCocktailDecoder : D.Decoder EventCocktail
eventCocktailDecoder =
    D.map2 EventCocktail
        (D.field "cocktailId" D.string)
        (D.field "portions" D.int)


-- Decodes the [[key, value]] list format back into a Dict.
dictDecoder : D.Decoder (Dict String Float)
dictDecoder =
    D.list pairDecoder
        |> D.map Dict.fromList


pairDecoder : D.Decoder ( String, Float )
pairDecoder =
    D.map2 Tuple.pair
        (D.index 0 D.string)
        (D.index 1 D.float)
