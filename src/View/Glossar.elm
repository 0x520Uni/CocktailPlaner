module View.Glossar exposing (view)

-- Glossar: cocktail browser as a near-fullscreen modal overlay.
-- Column 1: category list (or search-results header)
-- Column 2: cocktails in selected category (or search results)
-- Column 3: full cocktail detail (SVG + photo + ingredients + recipe)
--
-- When searchQuery is >= 2 characters, the Glossar switches to search mode:
-- column 1 shows a "search results" header and column 2 lists the matches.
-- Clearing the search box returns to the normal category-browsing mode.

import Dict
import Html exposing (Html, article, button, div, h2, h3, i, img, input, li, p, span, strong, text, ul)
import Html.Attributes exposing (alt, class, placeholder, src, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Types exposing (CategoriesState(..), CategoryState(..), CocktailSummary, FullCocktail, Ingredient, Model, Msg(..), Route(..))
import View.CocktailSvg


-- Renders the fullscreen modal overlay.
view : Model -> Html Msg
view model =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClick (NavigateTo HomeRoute) ] []
        , div
            [ class "modal-content"
            , style "width" "95vw"
            , style "height" "90vh"
            , style "background" "white"
            , style "border-radius" "8px"
            , style "overflow" "hidden"
            , style "display" "flex"
            , style "flex-direction" "column"
            ]
            [ modalHeader model
            , modalBody model
            ]
        , button [ class "modal-close is-large", onClick (NavigateTo HomeRoute) ] []
        ]


-- Header bar: title on the left, search box on the right.
modalHeader : Model -> Html Msg
modalHeader model =
    div
        [ class "has-background-dark px-5 py-4"
        , style "display" "flex"
        , style "align-items" "center"
        , style "gap" "1rem"
        ]
        [ h2 [ class "title has-text-white mb-0", style "flex-shrink" "0" ] [ text "Cocktail-Glossar" ]
        , -- Search box: always visible; drives name-search via Api.searchCocktailsByName.
          div [ class "field mb-0", style "flex" "1", style "max-width" "340px" ]
            [ div [ class "control has-icons-left has-icons-right" ]
                [ input
                    [ class "input is-small"
                    , type_ "text"
                    , placeholder "Cocktail suchen…"
                    , value model.searchQuery
                    , onInput GlossarSearchChanged
                    ]
                    []
                , span [ class "icon is-small is-left" ]
                    [ i [ class "fas fa-magnifying-glass" ] [] ]
                , -- Clear button: only shown when there is text in the search box.
                  if String.isEmpty model.searchQuery then
                    text ""

                  else
                    span
                        [ class "icon is-small is-right"
                        , style "pointer-events" "all"
                        , style "cursor" "pointer"
                        , onClick (GlossarSearchChanged "")
                        ]
                        [ i [ class "fas fa-xmark" ] [] ]
                ]
            ]
        ]


-- Three-column body filling the remaining height.
modalBody : Model -> Html Msg
modalBody model =
    div [ style "display" "flex", style "flex" "1", style "overflow" "hidden" ]
        [ columnCategories model
        , columnCocktailList model
        , columnDetail model
        ]


-- Column 1: category list in browse mode; "search results" label in search mode.
columnCategories : Model -> Html Msg
columnCategories model =
    div
        [ style "width" "200px"
        , style "border-right" "1px solid #dbdbdb"
        , style "overflow-y" "auto"
        , class "p-3 glossar-col-categories"
        ]
        [ if isSearchActive model then
            p [ class "has-text-grey is-size-7 has-text-weight-semibold" ]
                [ text ("Suchergebnisse für \"" ++ model.searchQuery ++ "\"") ]

          else
            categoryPanel model
        ]


-- Column 2: cocktail list from category (browse mode) or from search results (search mode).
columnCocktailList : Model -> Html Msg
columnCocktailList model =
    div
        [ style "width" "260px"
        , style "border-right" "1px solid #dbdbdb"
        , style "overflow-y" "auto"
        , class "p-3 glossar-col-list"
        ]
        [ if isSearchActive model then
            searchResultsPanel model

          else
            cocktailListPanel model
        ]


-- Column 3: cocktail detail — unchanged regardless of browse/search mode.
columnDetail : Model -> Html Msg
columnDetail model =
    div
        [ style "flex" "1"
        , style "overflow-y" "auto"
        , class "p-4"
        ]
        [ detailPanel model ]


-- True when the user has typed >= 2 characters in the search box.
isSearchActive : Model -> Bool
isSearchActive model =
    String.length model.searchQuery >= 2


-- Renders the category list based on loading state (browse mode only).
categoryPanel : Model -> Html Msg
categoryPanel model =
    case model.categoriesState of
        CategoriesNotLoaded ->
            p [ class "has-text-grey" ] [ text "Wird geladen..." ]

        CategoriesLoading ->
            p [ class "has-text-grey" ] [ text "Wird geladen..." ]

        CategoriesFailed ->
            p [ class "has-text-danger" ] [ text "Fehler beim Laden." ]

        CategoriesLoaded names ->
            ul [] (List.map (categoryItem model.selectedCategory) names)


-- A single category item; highlighted when it is the active selection.
categoryItem : Maybe String -> String -> Html Msg
categoryItem selectedCategory name =
    let
        isActive =
            selectedCategory == Just name

        activeStyle =
            if isActive then
                [ class "has-background-primary-light has-text-primary py-1 px-2"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                , style "list-style" "none"
                ]

            else
                [ class "py-1 px-2"
                , style "cursor" "pointer"
                , style "list-style" "none"
                , onClick (SelectCategory name)
                ]
    in
    li activeStyle [ text name ]


-- Renders search results as a cocktail list (search mode).
searchResultsPanel : Model -> Html Msg
searchResultsPanel model =
    if List.isEmpty model.glossarSearchResults then
        p [ class "has-text-grey" ] [ text "Keine Treffer." ]

    else
        ul [] (List.map (cocktailItem model.selectedCocktailId) (List.map fullCocktailToSummary model.glossarSearchResults))


-- Converts a FullCocktail to a CocktailSummary so we can reuse cocktailItem.
fullCocktailToSummary : FullCocktail -> CocktailSummary
fullCocktailToSummary c =
    { id = c.id, name = c.name, thumbnail = c.thumbnail }


-- Renders the cocktail list for the selected category (browse mode).
cocktailListPanel : Model -> Html Msg
cocktailListPanel model =
    case model.selectedCategory of
        Nothing ->
            p [ class "has-text-grey" ] [ text "← Kategorie auswählen" ]

        Just category ->
            case Dict.get category model.categories of
                Nothing ->
                    p [ class "has-text-grey" ] [ text "Wird geladen..." ]

                Just Loading ->
                    p [ class "has-text-grey" ] [ text "Wird geladen..." ]

                Just Failed ->
                    p [ class "has-text-danger" ] [ text "Fehler beim Laden." ]

                Just (Loaded summaries) ->
                    ul [] (List.map (cocktailItem model.selectedCocktailId) summaries)


-- A single cocktail list item; highlighted when selected.
cocktailItem : Maybe String -> CocktailSummary -> Html Msg
cocktailItem selectedId summary =
    let
        isActive =
            selectedId == Just summary.id

        itemClass =
            if isActive then
                "py-1 px-2 has-background-info-light has-text-info"

            else
                "py-1 px-2"
    in
    li
        [ class itemClass
        , style "cursor" "pointer"
        , style "list-style" "none"
        , style "border-radius" "4px"
        , onClick (SelectCocktail summary.id)
        ]
        [ text summary.name ]


-- Renders the cocktail detail in column 3.
detailPanel : Model -> Html Msg
detailPanel model =
    case model.selectedCocktailId of
        Nothing ->
            p [ class "has-text-grey" ] [ text "← Getränk auswählen" ]

        Just id ->
            -- Look up the full recipe in the cache; show a spinner until it arrives.
            case Dict.get id model.cocktailCache of
                Nothing ->
                    p [ class "has-text-grey" ] [ text "Wird geladen..." ]

                Just cocktail ->
                    cocktailDetail cocktail


-- Renders the full cocktail card: photo + SVG as a matched pair of framed media
-- cards, then ingredients and instructions. The whole panel is width-capped via
-- the "cocktail-detail" class so it stays readable on wide screens.
cocktailDetail : FullCocktail -> Html Msg
cocktailDetail cocktail =
    let
        -- Get the same colour list the SVG uses, so ingredient tags match the bands.
        colors =
            View.CocktailSvg.ingredientColors (List.length cocktail.ingredients)

        zipped =
            List.map2 Tuple.pair cocktail.ingredients colors
    in
    div [ class "cocktail-detail" ]
        [ h3 [ class "title is-4 mb-4" ] [ text cocktail.name ]

        -- Two framed cards: the real photo (left) and the proportion SVG (right).
        , div [ class "cocktail-media mb-5" ]
            [ mediaCard "Foto"
                (img
                    [ src cocktail.thumbnail
                    , alt cocktail.name
                    ]
                    []
                )
            , mediaCard "Verhältnis"
                (View.CocktailSvg.view cocktail.ingredients)
            ]

        -- Ingredients as coloured pill tags matching SVG layer colours.
        , div [ class "mb-5" ]
            [ p [ class "label mb-2" ] [ text "Zutaten" ]
            , div [ class "tags" ]
                (List.map ingredientTag zipped)
            ]

        -- Instructions in a subtle message box for better readability.
        , div []
            [ p [ class "label mb-2" ] [ text "Zubereitung" ]
            , article [ class "message is-light" ]
                [ div [ class "message-body" ]
                    [ p [ style "white-space" "pre-wrap" ]
                        [ text cocktail.instructions ]
                    ]
                ]
            ]
        ]


-- One framed media card: a small uppercase caption above centred content.
-- Used for both the photo and the SVG so they read as a matched pair.
mediaCard : String -> Html Msg -> Html Msg
mediaCard caption content =
    div [ class "media-card" ]
        [ span [ class "media-caption" ] [ text caption ]
        , div [ class "media-frame" ] [ content ]
        ]


-- One ingredient pill: coloured dot + name + measure, matching the SVG band colour.
ingredientTag : ( Ingredient, String ) -> Html Msg
ingredientTag ( ingredient, color ) =
    span
        [ class "tag is-light is-medium"
        , style "margin-right" "4px"
        , style "margin-bottom" "6px"
        ]
        [ span
            [ style "display" "inline-block"
            , style "width" "10px"
            , style "height" "10px"
            , style "border-radius" "50%"
            , style "background-color" color
            , style "margin-right" "5px"
            , style "flex-shrink" "0"
            ]
            []
        , strong [ style "margin-right" "3px" ] [ text ingredient.name ]
        , if String.isEmpty ingredient.measure then
            text ""

          else
            span [ style "color" "#888" ] [ text ("· " ++ ingredient.measure) ]
        ]
