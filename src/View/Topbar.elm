module View.Topbar exposing (view)

-- Persistent top navigation bar shown on every page (ADR-0007).
-- Contains route links and the Save / Load / Glossar buttons (ADR-0002).
-- On mobile (< 1024px) the links collapse behind a hamburger button.
-- The burger state is stored in model.burgerOpen (Elm-driven, no JS needed).
-- Icons use Font Awesome 6 classes (loaded via CDN in index.html).

import Html exposing (Html, a, button, div, i, nav, span, text)
import Html.Attributes exposing (class, classList, href)
import Html.Events exposing (onClick)
import Route
import Types exposing (Dialog(..), Model, Msg(..), Route(..))


-- Renders the full navbar with brand, hamburger, route links, and action buttons.
view : Model -> Html Msg
view model =
    nav [ class "navbar is-dark" ]
        [ div [ class "navbar-brand" ]
            [ span [ class "navbar-item has-text-weight-bold" ]
                [ text "CocktailPlaner" ]
            , -- Hamburger button: only visible on mobile (Bulma hides it on desktop).
              -- Sends ToggleBurger to flip model.burgerOpen; the menu div below reacts.
              button
                [ classList
                    [ ( "navbar-burger", True )
                    , ( "is-active", model.burgerOpen )
                    ]
                , onClick ToggleBurger
                ]
                [ span [] []
                , span [] []
                , span [] []
                ]
            ]
        , div
            [ classList
                [ ( "navbar-menu", True )
                , ( "is-active", model.burgerOpen )
                ]
            ]
            [ div [ class "navbar-start" ]
                [ navLink model HomeRoute "Planer"
                , navLink model ShoppingRoute "Einkaufsliste"
                ]
            , div [ class "navbar-end" ]
                [ div [ class "navbar-item" ]
                    [ -- Glossar: opens the cocktail glossary modal overlay.
                      iconButton "button is-info is-small mr-2" (NavigateTo GlossarRoute) "fas fa-book-open" "Glossar"
                    , -- Speichern: serialises current state to JSON for copy-paste backup.
                      iconButton "button is-light is-small mr-2" (OpenDialog SaveDialog) "fas fa-floppy-disk" "Speichern"
                    , -- Laden: lets the user paste previously saved JSON to restore state.
                      iconButton "button is-light is-small" (OpenDialog LoadDialog) "fas fa-folder-open" "Laden"
                    ]
                ]
            ]
        ]


-- Renders a navbar route link as an <a> tag.
-- Browser.application intercepts internal href clicks via LinkClicked, so SPA routing works.
-- Highlighted when the route matches the active one.
navLink : Model -> Route -> String -> Html Msg
navLink model route label =
    let
        isActive =
            model.route == route

        activeClass =
            if isActive then
                "navbar-item is-active"

            else
                "navbar-item"
    in
    a [ class activeClass, href (Route.toPath route) ]
        [ text label ]


-- Builds a Bulma icon+text button using a Font Awesome icon class.
-- faClass example: "fas fa-floppy-disk"
iconButton : String -> Msg -> String -> String -> Html Msg
iconButton btnClass msg faClass label =
    button [ class btnClass, onClick msg ]
        [ span [ class "icon is-small" ] [ i [ class faClass ] [] ]
        , span [] [ text label ]
        ]
