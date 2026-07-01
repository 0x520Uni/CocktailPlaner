module Main exposing (main)

-- Application entry point.
-- Only responsible for wiring: connecting Browser.application to init, update,
-- view, and subscriptions. All logic lives in the imported modules.

import Api
import Browser
import Browser.Navigation as Nav
import Codec
import Dict
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, classList, placeholder, readonly, rows, value)
import Html.Events exposing (onClick, onInput)
import Route
import Set
import Types exposing (..)
import Url exposing (Url)
import View.Glossar
import View.Home
import View.Shopping
import View.Topbar



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- INIT
-- Sets up the initial model when the app first loads.
-- The starting route is parsed from the URL the browser is already at.


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        startRoute =
            Route.fromUrl url

        initialModel =
            { key = key
            , route = startRoute
            , events = []
            , activeEventId = Nothing
            , nextEventId = 1
            , eventFormName = ""
            , eventFormGuestCount = "10"
            , eventSearchQuery = ""
            , eventSearchResults = []
            , selectedCocktailId = Nothing
            , cocktailCache = Dict.empty
            , categoriesState = CategoriesNotLoaded
            , categories = Dict.empty
            , selectedCategory = Nothing
            , searchQuery = ""
            , glossarSearchResults = []
            , activeDialog = NoDialog
            , importText = ""
            , packageSizes = Dict.empty
            , burgerOpen = False
            , eventFormError = Nothing
            , loadError = Nothing
            }
    in
    -- Fire a category fetch if the app starts on the Glossar route, and correct the
    -- address bar to "#/" if the app was opened at a bogus URL (e.g. an old "#/foobar").
    ( initialModel
    , Cmd.batch
        [ fetchCategoriesIfNeeded startRoute initialModel
        , redirectUnknownToHome key url
        ]
    )



-- UPDATE
-- Central dispatcher: every Msg variant is handled here.
-- As features grow, helper functions will be extracted below the case expression.


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            -- Parse the new URL and update the active route.
            -- Also fire a category fetch if the new route is the Glossar.
            -- Close the mobile burger menu whenever the route changes.
            let
                newRoute =
                    Route.fromUrl url
            in
            ( { model | route = newRoute, burgerOpen = False }
            , Cmd.batch
                [ fetchCategoriesIfNeeded newRoute model
                , redirectUnknownToHome model.key url
                ]
            )

        LinkClicked request ->
            -- Internal links push a new history entry; external links open normally.
            case request of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        OpenDialog dialog ->
            ( { model | activeDialog = dialog }, Cmd.none )

        CloseDialog ->
            ( { model | activeDialog = NoDialog, loadError = Nothing }, Cmd.none )

        ImportTextChanged text ->
            ( { model | importText = text }, Cmd.none )

        NavigateTo route ->
            -- Push a new URL so the browser history stays consistent.
            -- Mark categories Loading only when a fetch will actually run, so reopening an
            -- already-loaded Glossar keeps its list instead of hanging on the spinner.
            let
                updatedModel =
                    case route of
                        GlossarRoute ->
                            case model.categoriesState of
                                CategoriesNotLoaded ->
                                    { model | categoriesState = CategoriesLoading }

                                CategoriesFailed ->
                                    { model | categoriesState = CategoriesLoading }

                                _ ->
                                    model

                        _ ->
                            model
            in
            ( updatedModel
            , Cmd.batch
                [ Nav.pushUrl model.key (Route.toPath route)
                , fetchCategoriesIfNeeded route model
                ]
            )

        LoadProject ->
            -- Parse the JSON from the Load dialog textarea and restore user data.
            -- Only events, nextEventId, and packageSizes are restored; UI state resets.
            case Codec.parseState model.importText of
                Ok saved ->
                    -- A loaded project only stores cocktail IDs, not full recipes, so the
                    -- cache is empty. Fetch every referenced recipe now so names, ratio
                    -- glasses, and the shopping list all have their ingredient data.
                    ( { model
                        | events = saved.events
                        , nextEventId = saved.nextEventId
                        , packageSizes = saved.packageSizes
                        , activeDialog = NoDialog
                        , importText = ""
                        , loadError = Nothing
                        , activeEventId = Nothing
                      }
                    , fetchMissingRecipes model.cocktailCache
                        (List.concatMap (.cocktails >> List.map .cocktailId) saved.events)
                    )

                Err errMsg ->
                    ( { model | loadError = Just errMsg }, Cmd.none )

        GotCategories (Ok categoryNames) ->
            -- HTTP request succeeded: store the list and mark as loaded.
            ( { model | categoriesState = CategoriesLoaded categoryNames }, Cmd.none )

        GotCategories (Err _) ->
            -- HTTP request failed: mark as failed so the view can show an error.
            ( { model | categoriesState = CategoriesFailed }, Cmd.none )

        SelectCategory category ->
            -- User clicked a category: select it and fetch its cocktail list if not cached.
            let
                alreadyLoaded =
                    Dict.member category model.categories

                fetchCmd =
                    if alreadyLoaded then
                        Cmd.none

                    else
                        Api.fetchCocktailsByCategory category

                updatedCategories =
                    if alreadyLoaded then
                        model.categories

                    else
                        Dict.insert category Loading model.categories
            in
            ( { model | selectedCategory = Just category, categories = updatedCategories }
            , fetchCmd
            )

        GotCocktailSummaries category (Ok summaries) ->
            -- Store the fetched cocktail list for this category.
            ( { model | categories = Dict.insert category (Loaded summaries) model.categories }
            , Cmd.none
            )

        GotCocktailSummaries category (Err _) ->
            ( { model | categories = Dict.insert category Failed model.categories }
            , Cmd.none
            )

        SelectCocktail id ->
            -- User clicked a cocktail in column 2: show it in column 3.
            -- If the full recipe is already in the cache, no HTTP request is needed.
            let
                alreadyCached =
                    Dict.member id model.cocktailCache

                fetchCmd =
                    if alreadyCached then
                        Cmd.none

                    else
                        Api.fetchCocktailById id
            in
            ( { model | selectedCocktailId = Just id }, fetchCmd )

        GotFullCocktail (Ok cocktail) ->
            -- Store the full recipe in the cache keyed by cocktail ID.
            ( { model | cocktailCache = Dict.insert cocktail.id cocktail model.cocktailCache }
            , Cmd.none
            )

        GotFullCocktail (Err _) ->
            -- Failed to load recipe — clear the selection so column 3 shows the prompt again.
            ( { model | selectedCocktailId = Nothing }, Cmd.none )

        -- EVENT MANAGEMENT
        OpenCreateEvent ->
            -- Open the create dialog with a blank form and no previous error.
            ( { model | activeDialog = CreateEventDialog, eventFormName = "", eventFormGuestCount = "10", eventFormError = Nothing }
            , Cmd.none
            )

        EventFormNameChanged name ->
            ( { model | eventFormName = name }, Cmd.none )

        EventFormGuestCountChanged count ->
            ( { model | eventFormGuestCount = count }, Cmd.none )

        SaveEvent ->
            -- Create a new event from the modal form with validation.
            -- Validation rules: name must not be empty, name must not already exist.
            case model.activeDialog of
                CreateEventDialog ->
                    let
                        trimmedName =
                            String.trim model.eventFormName

                        nameEmpty =
                            String.isEmpty trimmedName

                        nameTaken =
                            List.any (\e -> e.name == trimmedName) model.events
                    in
                    if nameEmpty then
                        -- Show inline error; keep the dialog open.
                        ( { model | eventFormError = Just "Bitte einen Namen eingeben." }, Cmd.none )

                    else if nameTaken then
                        -- Show inline error; keep the dialog open.
                        ( { model | eventFormError = Just "Ein Event mit diesem Namen existiert bereits." }, Cmd.none )

                    else
                        let
                            guestCount =
                                String.toInt model.eventFormGuestCount |> Maybe.withDefault 10

                            newId =
                                String.fromInt model.nextEventId

                            newEvent =
                                { id = newId
                                , name = trimmedName
                                , guestCount = max 1 guestCount
                                , cocktails = []
                                }
                        in
                        ( { model
                            | events = model.events ++ [ newEvent ]
                            , nextEventId = model.nextEventId + 1
                            , activeDialog = NoDialog
                            , activeEventId = Just newId -- auto-open the new event in the detail panel
                            , eventFormError = Nothing
                          }
                        , Cmd.none
                        )

                _ ->
                    -- SaveEvent should not fire outside of a create dialog; ignore gracefully.
                    ( model, Cmd.none )

        DeleteEvent eventId ->
            -- Remove the event from the list.
            -- If the deleted event was active, auto-select the first remaining event
            -- so the detail panel does not go blank unnecessarily.
            let
                newEvents =
                    List.filter (\e -> e.id /= eventId) model.events

                newActiveId =
                    if model.activeEventId == Just eventId then
                        List.head newEvents |> Maybe.map .id

                    else
                        model.activeEventId
            in
            ( { model | events = newEvents, activeEventId = newActiveId }, Cmd.none )

        DuplicateEvent eventId ->
            -- Create a copy of the event with a new ID.
            -- If copies already exist, append a numbered suffix to avoid identical names.
            case List.filter (\e -> e.id == eventId) model.events |> List.head of
                Just event ->
                    let
                        baseName =
                            event.name ++ " (Kopie)"

                        -- Count existing events whose names start with the base copy name.
                        copyCount =
                            List.length (List.filter (\e -> String.startsWith baseName e.name) model.events)

                        copyName =
                            if copyCount == 0 then
                                baseName

                            else
                                baseName ++ " " ++ String.fromInt (copyCount + 1)

                        copy =
                            { event
                                | id = String.fromInt model.nextEventId
                                , name = copyName
                            }
                    in
                    ( { model
                        | events = model.events ++ [ copy ]
                        , nextEventId = model.nextEventId + 1
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        OpenEventDetail eventId ->
            -- Open an event in the right panel and reset the search state.
            -- Fetch any recipes still missing from the cache so the row glasses render.
            let
                cocktailIds =
                    List.filter (\e -> e.id == eventId) model.events
                        |> List.concatMap (.cocktails >> List.map .cocktailId)
            in
            ( { model
                | activeEventId = Just eventId
                , eventSearchQuery = ""
                , eventSearchResults = []
              }
            , fetchMissingRecipes model.cocktailCache cocktailIds
            )

        CloseEventDetail ->
            ( { model | activeEventId = Nothing }, Cmd.none )

        SetEventName eventId newName ->
            -- Inline edit: update the event name directly in the list, no dialog needed.
            let
                updatedEvents =
                    List.map
                        (\e ->
                            if e.id == eventId then
                                { e | name = newName }

                            else
                                e
                        )
                        model.events
            in
            ( { model | events = updatedEvents }, Cmd.none )

        SetEventGuestCount eventId countStr ->
            -- Inline edit: parse the string and update guestCount; ignore non-numeric input.
            let
                updatedEvents =
                    List.map
                        (\e ->
                            if e.id == eventId then
                                case String.toInt countStr of
                                    Just n ->
                                        { e | guestCount = max 1 n }

                                    Nothing ->
                                        e

                            else
                                e
                        )
                        model.events
            in
            ( { model | events = updatedEvents }, Cmd.none )

        -- EVENT COCKTAIL MANAGEMENT
        EventSearchChanged query ->
            ( { model | eventSearchQuery = query }, Cmd.none )

        SearchCocktailsForEvent ->
            -- Fire the API request only if the search field is not empty.
            if String.isEmpty (String.trim model.eventSearchQuery) then
                ( model, Cmd.none )

            else
                ( { model | eventSearchResults = [] }
                , Api.searchCocktailsByName model.eventSearchQuery GotEventSearchResults
                )

        GotEventSearchResults (Ok cocktails) ->
            -- Store all search results in the cocktail cache (they are full cocktails).
            -- This means the next time any of these cocktails is needed, no HTTP request is needed.
            let
                newCache =
                    List.foldl
                        (\c acc -> Dict.insert c.id c acc)
                        model.cocktailCache
                        cocktails
            in
            ( { model | eventSearchResults = cocktails, cocktailCache = newCache }, Cmd.none )

        GotEventSearchResults (Err _) ->
            ( { model | eventSearchResults = [] }, Cmd.none )

        GlossarSearchChanged query ->
            -- Fire a name-search when the query is at least 2 characters; clear results otherwise.
            if String.length query >= 2 then
                ( { model | searchQuery = query }
                , Api.searchCocktailsByName query GotGlossarSearchResults
                )

            else
                ( { model | searchQuery = query, glossarSearchResults = [] }, Cmd.none )

        GotGlossarSearchResults (Ok results) ->
            -- Store full cocktails in the shared cache and keep the list for the Glossar search view.
            let
                newCache =
                    List.foldl (\c acc -> Dict.insert c.id c acc) model.cocktailCache results
            in
            ( { model | glossarSearchResults = results, cocktailCache = newCache }, Cmd.none )

        GotGlossarSearchResults (Err _) ->
            ( { model | glossarSearchResults = [] }, Cmd.none )

        AddCocktailToEvent cocktailId ->
            -- Add the cocktail to the active event with 1 portion.
            -- If the cocktail is already in the event, increment its portions by 1
            -- instead of silently doing nothing — this gives the user visible feedback.
            case model.activeEventId of
                Nothing ->
                    ( model, Cmd.none )

                Just eventId ->
                    let
                        updatedEvents =
                            List.map
                                (\e ->
                                    if e.id == eventId then
                                        let
                                            alreadyThere =
                                                List.any (\ec -> ec.cocktailId == cocktailId) e.cocktails
                                        in
                                        if alreadyThere then
                                            -- Cocktail already present: bump its portions instead.
                                            { e
                                                | cocktails =
                                                    List.map
                                                        (\ec ->
                                                            if ec.cocktailId == cocktailId then
                                                                { ec | portions = ec.portions + 1 }

                                                            else
                                                                ec
                                                        )
                                                        e.cocktails
                                            }

                                        else
                                            { e | cocktails = e.cocktails ++ [ { cocktailId = cocktailId, portions = 1 } ] }

                                    else
                                        e
                                )
                                model.events
                    in
                    ( { model | events = updatedEvents }, Cmd.none )

        RemoveCocktailFromEvent cocktailId ->
            -- Remove the cocktail from the active event's cocktail list.
            case model.activeEventId of
                Nothing ->
                    ( model, Cmd.none )

                Just eventId ->
                    let
                        updatedEvents =
                            List.map
                                (\e ->
                                    if e.id == eventId then
                                        { e | cocktails = List.filter (\ec -> ec.cocktailId /= cocktailId) e.cocktails }

                                    else
                                        e
                                )
                                model.events
                    in
                    ( { model | events = updatedEvents }, Cmd.none )

        SetPackageSize ingredientName size ->
            -- User clicked a preset for one ingredient's package size.
            ( { model | packageSizes = Dict.insert ingredientName size model.packageSizes }
            , Cmd.none
            )

        ToggleBurger ->
            -- Toggle the mobile hamburger menu open or closed.
            ( { model | burgerOpen = not model.burgerOpen }, Cmd.none )

        OpenShoppingForEvent eventId ->
            -- Activate a specific event and navigate to the shopping list page.
            -- This fixes the bug where the Einkaufsliste button always showed the active
            -- event instead of the event whose button was clicked.
            -- Also fetch any missing recipes so the shopping list can compute right away.
            let
                cocktailIds =
                    List.filter (\e -> e.id == eventId) model.events
                        |> List.concatMap (.cocktails >> List.map .cocktailId)
            in
            ( { model | activeEventId = Just eventId }
            , Cmd.batch
                [ Nav.pushUrl model.key (Route.toPath ShoppingRoute)
                , fetchMissingRecipes model.cocktailCache cocktailIds
                ]
            )

        SetPortions cocktailId newPortions ->
            -- Update the portion count for one cocktail in the active event.
            -- Minimum is 1 so the user cannot accidentally set zero.
            case model.activeEventId of
                Nothing ->
                    ( model, Cmd.none )

                Just eventId ->
                    let
                        safePortions =
                            max 1 newPortions

                        updatedEvents =
                            List.map
                                (\e ->
                                    if e.id == eventId then
                                        { e
                                            | cocktails =
                                                List.map
                                                    (\ec ->
                                                        if ec.cocktailId == cocktailId then
                                                            { ec | portions = safePortions }

                                                        else
                                                            ec
                                                    )
                                                    e.cocktails
                                        }

                                    else
                                        e
                                )
                                model.events
                    in
                    ( { model | events = updatedEvents }, Cmd.none )



-- SUBSCRIPTIONS
-- No subscriptions needed yet.


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Rewrites the address bar to the Events home page ("#/") when the URL carries no known
-- route. fromUrl already renders Events in that case; this just cleans up the visible URL.
-- Uses replaceUrl (not pushUrl) so the bogus URL leaves no back-button entry.


redirectUnknownToHome : Nav.Key -> Url -> Cmd Msg
redirectUnknownToHome key url =
    case Route.parse url of
        Just _ ->
            Cmd.none

        Nothing ->
            Nav.replaceUrl key (Route.toPath HomeRoute)



-- Fetches full recipes for every cocktail ID not yet in the cache (e.g. right after a
-- project is loaded), so names, ratio glasses, and the shopping list have their data.
-- Duplicate IDs are collapsed via Set so each recipe is requested at most once.


fetchMissingRecipes : Dict.Dict String FullCocktail -> List String -> Cmd Msg
fetchMissingRecipes cache ids =
    ids
        |> List.filter (\id -> not (Dict.member id cache))
        |> Set.fromList
        |> Set.toList
        |> List.map Api.fetchCocktailById
        |> Cmd.batch



-- Returns Api.fetchCategories only when navigating to GlossarRoute and not yet loaded.
-- Cmd.none in all other cases so nothing fires unnecessarily.


fetchCategoriesIfNeeded : Route -> Model -> Cmd Msg
fetchCategoriesIfNeeded route model =
    case ( route, model.categoriesState ) of
        ( GlossarRoute, CategoriesNotLoaded ) ->
            Api.fetchCategories

        ( GlossarRoute, CategoriesFailed ) ->
            Api.fetchCategories

        _ ->
            Cmd.none



-- VIEW
-- Renders the full page: topbar + the active route's content area + app-level dialogs.


view : Model -> Browser.Document Msg
view model =
    { title = "CocktailPlaner"
    , body =
        [ View.Topbar.view model
        , routeView model
        , saveDialog model
        , loadDialog model
        ]
    }



-- Save dialog: shows the serialised JSON so the user can copy it.
-- The textarea is read-only; the user selects all and copies to the clipboard.


saveDialog : Model -> Html Msg
saveDialog model =
    if model.activeDialog == SaveDialog then
        div [ class "modal is-active" ]
            [ div [ class "modal-background", onClick CloseDialog ] []
            , div [ class "modal-card" ]
                [ div [ class "modal-card-head" ]
                    [ div [ class "modal-card-title" ] [ text "Projekt speichern" ]
                    , button [ class "delete", onClick CloseDialog ] []
                    ]
                , div [ class "modal-card-body" ]
                    [ Html.p [ class "mb-3" ]
                        [ text "Kopiere den Text und speichere ihn z. B. in einer Textdatei. Beim nächsten Mal kannst du ihn im \"Laden\"-Dialog einfügen." ]
                    , Html.textarea
                        [ class "textarea is-family-monospace"
                        , rows 12
                        , readonly True
                        , value (Codec.encodeToString model)
                        ]
                        []
                    ]
                , div [ class "modal-card-foot" ]
                    [ button [ class "button", onClick CloseDialog ] [ text "Schließen" ]
                    ]
                ]
            ]

    else
        text ""



-- Load dialog: the user pastes saved JSON, then clicks "Laden".
-- Shows an error message if the JSON cannot be parsed.


loadDialog : Model -> Html Msg
loadDialog model =
    if model.activeDialog == LoadDialog then
        div [ class "modal is-active" ]
            [ div [ class "modal-background", onClick CloseDialog ] []
            , div [ class "modal-card" ]
                [ div [ class "modal-card-head" ]
                    [ div [ class "modal-card-title" ] [ text "Projekt laden" ]
                    , button [ class "delete", onClick CloseDialog ] []
                    ]
                , div [ class "modal-card-body" ]
                    [ if List.isEmpty model.events then
                        text ""

                      else
                        Html.article [ class "message is-warning mb-3" ]
                            [ div [ class "message-body" ]
                                [ text "Es ist bereits ein Projekt offen. Laden überschreibt alle aktuellen Daten." ]
                            ]
                    , Html.p [ class "mb-3" ]
                        [ text "Füge den gespeicherten Text ein und klicke auf \"Laden\"." ]
                    , Html.textarea
                        [ class "textarea is-family-monospace"
                        , rows 12
                        , placeholder "{ \"events\": [ ... ] }"
                        , value model.importText
                        , onInput ImportTextChanged
                        ]
                        []
                    , case model.loadError of
                        Just errMsg ->
                            Html.p [ class "has-text-danger mt-2" ] [ text errMsg ]

                        Nothing ->
                            text ""
                    ]
                , div [ class "modal-card-foot" ]
                    [ button
                        [ class "button is-primary"
                        , onClick LoadProject
                        ]
                        [ text "Laden" ]
                    , button [ class "button ml-2", onClick CloseDialog ] [ text "Abbrechen" ]
                    ]
                ]
            ]

    else
        text ""



-- Picks the correct page view based on the active route.
-- GlossarRoute renders Home in the background with the Glossar modal on top.


routeView : Model -> Html Msg
routeView model =
    case model.route of
        HomeRoute ->
            View.Home.view model

        ShoppingRoute ->
            View.Shopping.view model

        GlossarRoute ->
            div []
                [ View.Home.view model
                , View.Glossar.view model
                ]
