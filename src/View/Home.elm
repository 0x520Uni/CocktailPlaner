module View.Home exposing (view)

-- Home page: event management.
-- Left column: event cards — clicking the card body opens it in the detail panel.
--   Card footer: Duplizieren · Einkaufsliste · Löschen.
-- Right column: detail panel with inline-editable name/guest count + cocktail list + search.
--   Empty state: subtle visual placeholder, no redundant instruction text.
-- Modal: only for creating a new event (editing is inline in the detail panel).

import Dict
import Html exposing (Html, a, button, div, h1, input, label, p, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, placeholder, style, type_, value)
import Html.Events exposing (on, onClick, onInput)
import Html.Keyed as Keyed
import Json.Decode as Decode
import Types exposing (Dialog(..), Event, EventCocktail, FullCocktail, Model, Msg(..), Route(..))



-- TOP-LEVEL VIEW


-- Renders the whole home page: modal (if open) + header bar + two-column layout.
view : Model -> Html Msg
view model =
    div [ class "section" ]
        [ div [ class "container is-fluid" ]
            [ eventModal model
            , pageHeader
            , div [ class "columns mt-4" ]
                [ div [ class "column is-5" ]
                    [ eventListView model ]
                , div [ class "column is-7" ]
                    [ eventDetailView model ]
                ]
            ]
        ]


-- Top bar: page title on the left, "New Event" button on the right.
pageHeader : Html Msg
pageHeader =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ h1 [ class "title" ] [ text "Meine Events" ] ]
        , div [ class "level-right" ]
            [ button [ class "button is-primary", onClick OpenCreateEvent ]
                [ text "+ Neues Event erstellen" ]
            ]
        ]



-- EVENT LIST (left column)


-- Shows all events as cards, or an onboarding prompt when there are none yet.
eventListView : Model -> Html Msg
eventListView model =
    if List.isEmpty model.events then
        div [ class "has-text-grey has-text-centered mt-6" ]
            [ p [ class "is-size-5" ] [ text "Noch keine Events." ]
            , p [] [ text "Klicke auf \"+ Neues Event erstellen\" um loszulegen." ]
            ]

    else
        div [] (List.map (eventCard model.activeEventId) model.events)


-- One event as a Bulma card.
-- The card-content area is clickable and opens the event in the right panel.
-- The card-footer holds secondary actions that do NOT open the event.
eventCard : Maybe String -> Event -> Html Msg
eventCard activeId event =
    let
        isActive =
            activeId == Just event.id

        cardClass =
            if isActive then
                "card mb-3 has-background-info-light"

            else
                "card mb-3"

        cocktailCount =
            List.length event.cocktails

        countLabel =
            String.fromInt cocktailCount
                ++ (if cocktailCount == 1 then
                        " Cocktail"

                    else
                        " Cocktails"
                   )

        guestLabel =
            String.fromInt event.guestCount
                ++ (if event.guestCount == 1 then
                        " Gast"

                    else
                        " G\u{00E4}ste"
                   )
    in
    div [ class cardClass ]
        [ -- Clicking the content area opens the event in the right panel.
          div
            [ class "card-content"
            , style "cursor" "pointer"
            , onClick (OpenEventDetail event.id)
            ]
            [ -- Flex row: name can shrink (min-width: 0) so long names don't push the tag off-screen.
              div [ class "is-flex is-justify-content-space-between is-align-items-flex-start", style "min-width" "0" ]
                [ p [ class "title is-5 mb-1 card-event-name" ] [ text event.name ]
                , if isActive then
                    span [ class "tag is-info", style "flex-shrink" "0", style "margin-left" "0.5rem" ] [ text "Aktiv" ]

                  else
                    text ""
                ]
            , p [ class "subtitle is-6 mb-0 has-text-grey" ]
                [ text (countLabel ++ " · " ++ guestLabel) ]
            ]
        , -- Footer: buttons instead of <a> tags — <a> without href triggers Browser.application's
          -- link interceptor (Nav.load ""), which reloads the page and wipes all state.
          div [ class "card-footer" ]
            [ button [ class "card-footer-item card-footer-btn", onClick (DuplicateEvent event.id) ]
                [ text "Duplizieren" ]
            , button [ class "card-footer-item card-footer-btn", onClick (OpenShoppingForEvent event.id) ]
                [ text "Einkaufsliste" ]
            , button [ class "card-footer-item card-footer-btn has-text-danger", onClick (DeleteEvent event.id) ]
                [ text "L\u{00F6}schen" ]
            ]
        ]



-- EVENT DETAIL (right column)


-- Shows the detail panel for the active event, or a visual placeholder.
eventDetailView : Model -> Html Msg
eventDetailView model =
    case model.activeEventId of
        Nothing ->
            -- Subtle empty state: visual contrast signals "select something on the left"
            -- without duplicating the instruction text from the left column.
            div [ class "event-empty-state" ]
                [ p [ class "event-empty-icon" ] [ text "🍸" ]
                , p [ class "has-text-grey is-size-6" ] [ text "Kein Event ausgewählt" ]
                ]

        Just eventId ->
            case List.filter (\e -> e.id == eventId) model.events |> List.head of
                Nothing ->
                    text ""

                Just event ->
                    -- Keyed so the fadeIn animation fires each time a different event is opened.
                    Keyed.node "div"
                        []
                        [ ( "detail-" ++ eventId
                          , div [ class "box animate__animated animate__fadeIn" ]
                                [ detailHeader event
                                , cocktailListView model event
                                , div [ class "mt-5" ] [ cocktailSearchView model ]
                                ]
                          )
                        ]


-- Inline-editable header for the active event.
-- The inputs look like plain text; a bottom border appears on hover/focus (see style.css).
-- Changes are saved immediately to the event list — no save button needed.
detailHeader : Event -> Html Msg
detailHeader event =
    div [ class "mb-4" ]
        [ div [ class "is-flex is-justify-content-space-between is-align-items-flex-start" ]
            [ -- min-width: 0 is needed on a flex child so the input can shrink below its natural width.
              div [ class "is-flex-grow-1 mr-4", style "min-width" "0" ]
                [ p [ class "is-size-7 has-text-grey mb-1" ] [ text "Eventname \u{270F}" ]
                , input
                    [ class "inline-edit-name"
                    , type_ "text"
                    , value event.name
                    , onInput (SetEventName event.id)
                    ]
                    []
                ]
            , button [ class "button is-small is-light", style "flex-shrink" "0", onClick CloseEventDetail ]
                [ text "\u{00D7}" ]
            ]
        , div [ class "is-flex is-align-items-center mt-3" ]
            [ p [ class "is-size-7 has-text-grey mr-2" ] [ text "G\u{00E4}ste \u{270F}" ]
            , input
                [ class "inline-edit-number"
                , type_ "number"
                , value (String.fromInt event.guestCount)
                , onInput (SetEventGuestCount event.id)
                ]
                []
            ]
        ]



-- COCKTAIL LIST


-- The table of cocktails added to the event, or a placeholder when empty.
cocktailListView : Model -> Event -> Html Msg
cocktailListView model event =
    if List.isEmpty event.cocktails then
        p [ class "has-text-grey-light mt-3" ]
            [ text "Noch keine Cocktails \u{2014} suche unten, um welche hinzuzuf\u{00FC}gen." ]

    else
        table [ class "table is-fullwidth is-striped is-narrow mt-3" ]
            [ thead []
                [ tr []
                    [ th [] [ text "Cocktail" ]
                    , th [] [ text "Portionen" ]
                    , th [] []
                    ]
                ]
            , tbody [] (List.map (cocktailRow model) event.cocktails)
            ]


-- One row: cocktail name, portion counter (−/number/+), remove button.
cocktailRow : Model -> EventCocktail -> Html Msg
cocktailRow model ec =
    let
        -- Look up the cocktail name from the cache; fall back to the raw ID if not cached.
        cocktailName =
            case Dict.get ec.cocktailId model.cocktailCache of
                Just c ->
                    c.name

                Nothing ->
                    ec.cocktailId
    in
    tr []
        [ td [] [ text cocktailName ]
        , td []
            [ div [ class "field has-addons" ]
                [ div [ class "control" ]
                    [ button
                        [ class "button is-small"
                        , onClick (SetPortions ec.cocktailId (ec.portions - 1))
                        ]
                        [ text "\u{2212}" ]
                    ]
                , div [ class "control" ]
                    [ input
                        [ class "input is-small"
                        , type_ "number"
                        , style "width" "4rem"
                        , value (String.fromInt ec.portions)
                        , onInput
                            (\s ->
                                SetPortions ec.cocktailId
                                    (Maybe.withDefault ec.portions (String.toInt s))
                            )
                        ]
                        []
                    ]
                , div [ class "control" ]
                    [ button
                        [ class "button is-small"
                        , onClick (SetPortions ec.cocktailId (ec.portions + 1))
                        ]
                        [ text "+" ]
                    ]
                ]
            ]
        , td []
            [ button
                [ class "button is-small is-danger is-light"
                , onClick (RemoveCocktailFromEvent ec.cocktailId)
                ]
                [ text "\u{00D7}" ]
            ]
        ]



-- COCKTAIL SEARCH (inside the detail panel)


-- Search input + button + results list.
-- Search fires on Enter key press OR on clicking the "Suchen" button (no debounce).
cocktailSearchView : Model -> Html Msg
cocktailSearchView model =
    div []
        [ p [ class "label" ] [ text "Cocktail hinzuf\u{00FC}gen" ]
        , div [ class "field has-addons mb-3" ]
            [ div [ class "control is-expanded" ]
                [ input
                    [ class "input"
                    , type_ "text"
                    , placeholder "Cocktailname, z. B. Mojito \u{2026}"
                    , value model.eventSearchQuery
                    , onInput EventSearchChanged
                    , on "keydown" (enterDecoder SearchCocktailsForEvent)
                    ]
                    []
                ]
            , div [ class "control" ]
                [ button
                    [ class "button is-info"
                    , onClick SearchCocktailsForEvent
                    ]
                    [ text "Suchen" ]
                ]
            ]
        , searchResultsView model.eventSearchResults
        ]


-- Succeeds only when the pressed key is Enter; used to submit the search without a button click.
enterDecoder : Msg -> Decode.Decoder Msg
enterDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\key ->
                if key == "Enter" then
                    Decode.succeed msg

                else
                    Decode.fail "not enter"
            )


-- Shows the search result list, or nothing when there are no results yet.
searchResultsView : List FullCocktail -> Html Msg
searchResultsView results =
    if List.isEmpty results then
        text ""

    else
        div [ class "panel" ]
            (p [ class "panel-heading is-size-7" ] [ text "Suchergebnisse" ]
                :: List.map searchResultItem results
            )


-- One result row: cocktail name on the left, "+ Hinzufügen" button on the right.
searchResultItem : FullCocktail -> Html Msg
searchResultItem cocktail =
    div [ class "panel-block" ]
        [ span [ class "is-flex-grow-1" ] [ text cocktail.name ]
        , button
            [ class "button is-small is-success is-light"
            , onClick (AddCocktailToEvent cocktail.id)
            ]
            [ text "+ Hinzuf\u{00FC}gen" ]
        ]



-- CREATE MODAL


-- Renders the Bulma modal for creating a new event.
-- Only visible when activeDialog == CreateEventDialog.
-- Editing an existing event is done inline in the detail panel, not via this modal.
eventModal : Model -> Html Msg
eventModal model =
    let
        isActive =
            model.activeDialog == CreateEventDialog

        modalClass =
            if isActive then
                "modal is-active"

            else
                "modal"
    in
    div [ class modalClass ]
        [ div [ class "modal-background", onClick CloseDialog ] []
        , div [ class "modal-card" ]
            [ div [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "Neues Event erstellen" ]
                , button [ class "delete", onClick CloseDialog ] []
                ]
            , div [ class "modal-card-body" ]
                [ div [ class "field" ]
                    [ label [ class "label" ] [ text "Name" ]
                    , div [ class "control" ]
                        [ input
                            [ class
                                (if model.eventFormError /= Nothing then
                                    "input is-danger"

                                 else
                                    "input"
                                )
                            , type_ "text"
                            , placeholder "z. B. Sommerfest"
                            , value model.eventFormName
                            , onInput EventFormNameChanged
                            ]
                            []
                        ]
                    , case model.eventFormError of
                        Just err ->
                            p [ class "help is-danger" ] [ text err ]

                        Nothing ->
                            text ""
                    ]
                , div [ class "field" ]
                    [ label [ class "label" ] [ text "Anzahl G\u{00E4}ste" ]
                    , div [ class "control" ]
                        [ input
                            [ class "input"
                            , type_ "number"
                            , value model.eventFormGuestCount
                            , onInput EventFormGuestCountChanged
                            ]
                            []
                        ]
                    ]
                ]
            , div [ class "modal-card-foot" ]
                [ button [ class "button is-primary", onClick SaveEvent ]
                    [ text "Erstellen" ]
                , button [ class "button", onClick CloseDialog ]
                    [ text "Abbrechen" ]
                ]
            ]
        ]
