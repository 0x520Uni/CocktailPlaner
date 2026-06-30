module Api exposing (fetchCategories, fetchCocktailsByCategory, fetchCocktailById, searchCocktailsByName)

-- HTTP commands for TheCocktailDB API.
-- Each function returns a Cmd Msg that the runtime executes.
-- The response is delivered back as a Msg to Main.update.

import Http
import Json.Decode as Decode exposing (Decoder)
import Types exposing (CocktailSummary, FullCocktail, Ingredient, IngredientAmount(..), Msg(..))
import Url



-- CATEGORY LIST


-- Fetches all available category names from TheCocktailDB.
-- Endpoint: list.php?c=list
-- Response: { "drinks": [{ "strCategory": "Cocktail" }, ...] }
fetchCategories : Cmd Msg
fetchCategories =
    Http.get
        { url = "https://www.thecocktaildb.com/api/json/v1/1/list.php?c=list"
        , expect = Http.expectJson GotCategories categoriesDecoder
        }


-- Decodes the list.php response into a plain list of category name strings.
categoriesDecoder : Decoder (List String)
categoriesDecoder =
    Decode.field "drinks"
        (Decode.list (Decode.field "strCategory" Decode.string))



-- COCKTAIL LIST BY CATEGORY


-- Fetches the cocktails belonging to one category.
-- Endpoint: filter.php?c=<category>
-- Response: { "drinks": [{ "strDrink": "...", "strDrinkThumb": "...", "idDrink": "..." }, ...] }
-- Note: only summary data — no ingredients or recipe.
fetchCocktailsByCategory : String -> Cmd Msg
fetchCocktailsByCategory category =
    Http.get
        { url = "https://www.thecocktaildb.com/api/json/v1/1/filter.php?c=" ++ Url.percentEncode category
        , expect = Http.expectJson (GotCocktailSummaries category) cocktailSummariesDecoder
        }


-- Decodes the filter.php response into a list of CocktailSummary records.
cocktailSummariesDecoder : Decoder (List CocktailSummary)
cocktailSummariesDecoder =
    Decode.field "drinks"
        (Decode.list
            (Decode.map3 CocktailSummary
                (Decode.field "idDrink" Decode.string)
                (Decode.field "strDrink" Decode.string)
                (Decode.field "strDrinkThumb" Decode.string)
            )
        )



-- FULL COCKTAIL BY ID


-- Fetches the complete recipe for one cocktail.
-- Endpoint: lookup.php?i=<id>
-- Response: { "drinks": [{ full cocktail object }] }
fetchCocktailById : String -> Cmd Msg
fetchCocktailById id =
    Http.get
        { url = "https://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=" ++ id
        , expect = Http.expectJson GotFullCocktail fullCocktailDecoder
        }


-- Decodes the lookup.php response — takes the first element of the "drinks" array.
fullCocktailDecoder : Decoder FullCocktail
fullCocktailDecoder =
    Decode.field "drinks" (Decode.index 0 drinkObjectDecoder)



-- COCKTAIL SEARCH BY NAME


-- Searches for cocktails by name.
-- Endpoint: search.php?s=<name>
-- Response: { "drinks": [ full cocktail objects ... ] } or { "drinks": null } if no match.
-- The caller supplies the Msg constructor so the same function works for both
-- the event cocktail search (GotEventSearchResults) and the Glossar search (GotGlossarSearchResults).
searchCocktailsByName : String -> (Result Http.Error (List FullCocktail) -> Msg) -> Cmd Msg
searchCocktailsByName query toMsg =
    Http.get
        { url = "https://www.thecocktaildb.com/api/json/v1/1/search.php?s=" ++ Url.percentEncode query
        , expect = Http.expectJson toMsg searchResultsDecoder
        }


-- Decodes the search.php response.
-- The API returns { "drinks": null } when nothing matches, so we handle null → empty list.
searchResultsDecoder : Decoder (List FullCocktail)
searchResultsDecoder =
    Decode.field "drinks"
        (Decode.oneOf
            [ Decode.list drinkObjectDecoder
            , Decode.null []
            ]
        )



-- SHARED DRINK DECODER


-- Decodes a single drink object from the API (used by both lookup.php and search.php).
-- Extracted so it can be used inside both a single-item and a list context.
drinkObjectDecoder : Decoder FullCocktail
drinkObjectDecoder =
    Decode.map5 FullCocktail
        (Decode.field "idDrink" Decode.string)
        (Decode.field "strDrink" Decode.string)
        (Decode.field "strDrinkThumb" Decode.string)
        ingredientsDecoder
        (Decode.field "strInstructions" Decode.string)


-- The API stores ingredients in numbered fields: strIngredient1…strIngredient15
-- with matching strMeasure1…strMeasure15. This decoder walks all 15 slots,
-- skips empty/null ones, and builds a clean list.
ingredientsDecoder : Decoder (List Ingredient)
ingredientsDecoder =
    Decode.value
        |> Decode.andThen
            (\rawValue ->
                let
                    -- Try to read one numbered ingredient slot; Nothing if empty or missing.
                    readSlot : Int -> Maybe Ingredient
                    readSlot n =
                        let
                            nStr =
                                String.fromInt n

                            nameResult =
                                Decode.decodeValue
                                    (Decode.field ("strIngredient" ++ nStr) Decode.string)
                                    rawValue

                            measureResult =
                                Decode.decodeValue
                                    (Decode.field ("strMeasure" ++ nStr) Decode.string)
                                    rawValue
                        in
                        case nameResult of
                            Ok name ->
                                if String.isEmpty (String.trim name) then
                                    Nothing

                                else
                                    let
                                        measure =
                                            case measureResult of
                                                Ok m ->
                                                    String.trim m

                                                Err _ ->
                                                    ""
                                    in
                                    Just { name = String.trim name, measure = measure, amount = parseMeasureToAmount measure }

                            Err _ ->
                                Nothing
                in
                Decode.succeed (List.filterMap readSlot (List.range 1 15))
            )



-- MEASURE-TO-AMOUNT CONVERSION


-- Converts a raw API measure string ("1 1/2 oz", "2 cl", "3") to an IngredientAmount.
-- Strategy: detect the unit keyword first, then extract the leading number and multiply.
-- Units are checked longest-first to avoid "tsp" matching inside "tbsp".
parseMeasureToAmount : String -> IngredientAmount
parseMeasureToAmount raw =
    let
        lower =
            String.toLower (String.trim raw)

        number =
            extractLeadingNumber raw
    in
    if String.contains "oz" lower then
        -- Fluid ounce: 1 oz = 29.57 ml (standard for cocktail recipes).
        Maybe.map (\n -> LiquidMl (n * 29.57)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "tblsp" lower || String.contains "tbsp" lower then
        -- Tablespoon: 1 tbsp = 15 ml. Check before "tsp" to avoid partial match.
        Maybe.map (\n -> LiquidMl (n * 15)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "tsp" lower then
        -- Teaspoon: 1 tsp = 5 ml.
        Maybe.map (\n -> LiquidMl (n * 5)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "cl" lower then
        -- Centilitre: 1 cl = 10 ml. Check before "l" to avoid partial match.
        Maybe.map (\n -> LiquidMl (n * 10)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "ml" lower then
        -- Millilitre: already the target unit.
        Maybe.map LiquidMl number |> Maybe.withDefault UnknownAmount

    else if String.contains "cup" lower then
        -- US cup: 1 cup = 240 ml.
        Maybe.map (\n -> LiquidMl (n * 240)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "shot" lower then
        -- Shot glass: 1 shot = 44 ml (standard 1.5 oz jigger).
        Maybe.map (\n -> LiquidMl (n * 44)) number |> Maybe.withDefault UnknownAmount

    else if String.contains "dash" lower then
        -- Cocktail dash ≈ 0.6 ml. "dash" alone (no number) counts as one dash.
        Maybe.map (\n -> LiquidMl (n * 0.6)) number |> Maybe.withDefault (LiquidMl 0.6)

    else if String.contains "drop" lower then
        -- Drop ≈ 0.05 ml (e.g. bitters counted drop by drop).
        Maybe.map (\n -> LiquidMl (n * 0.05)) number |> Maybe.withDefault UnknownAmount

    else if List.member "l" (String.words lower) || List.member "liter" (String.words lower) then
        -- Litre: match the exact word "l" to avoid false positives in words like "alcohol".
        -- "cl"/"ml" are already handled above, so only plain "l" reaches here.
        Maybe.map (\n -> LiquidMl (n * 1000)) number |> Maybe.withDefault UnknownAmount

    else
        -- No known liquid unit: a bare number is a piece count (e.g. "3" limes).
        -- Anything else (garnish, "Top", empty) is unknown.
        case number of
            Just n ->
                PieceCount n

            Nothing ->
                UnknownAmount


-- Extracts the leading numeric value from a measure string.
-- Handles: integers, decimals, fractions ("3/4"), mixed numbers ("1 1/2"),
-- and ranges ("6-8" → lower bound 6).
extractLeadingNumber : String -> Maybe Float
extractLeadingNumber raw =
    case String.words (String.trim raw) of
        [] ->
            Nothing

        first :: rest ->
            case parseNumericToken first of
                Just n ->
                    -- If the next word is a fraction like "1/2", add it (mixed number).
                    case rest of
                        next :: _ ->
                            case parseFractionToken next of
                                Just f ->
                                    Just (n + f)

                                Nothing ->
                                    Just n

                        [] ->
                            Just n

                Nothing ->
                    Nothing


-- Parses a single numeric token: plain number, decimal, fraction "3/4",
-- or range "6-8" (returns lower bound).
parseNumericToken : String -> Maybe Float
parseNumericToken rawToken =
    let
        -- For a range like "6-8", keep only the lower bound "6".
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


-- Parses only slash-fractions like "1/2". Returns Nothing for everything else.
parseFractionToken : String -> Maybe Float
parseFractionToken s =
    case String.split "/" s of
        [ num, den ] ->
            Maybe.map2 (/) (String.toFloat num) (String.toFloat den)

        _ ->
            Nothing
