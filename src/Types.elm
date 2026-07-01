module Types exposing (..)

-- Central type definitions for the entire application.
-- Every other module imports from here so types are defined exactly once.

import Browser
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Http
import Url exposing (Url)



-- ROUTING
-- The three top-level pages of the app (ADR-0007).


type Route
    = HomeRoute
    | ShoppingRoute
    | GlossarRoute



-- PERSISTENCE DIALOGS
-- Controls which modal dialog is currently open (ADR-0002).
-- CreateEventDialog is for the new-event form; editing happens inline in the detail panel.


type Dialog
    = NoDialog
    | SaveDialog
    | LoadDialog
    | CreateEventDialog



-- COCKTAIL DATA
-- Lightweight cocktail info returned by filter.php (category endpoint).
-- Only has name, ID, and thumbnail — no recipe.


type alias CocktailSummary =
    { id : String
    , name : String
    , thumbnail : String
    }



-- Full cocktail data returned by lookup.php or search.php.
-- Ingredients are already converted to ml when this is stored in the cache (ADR-0008).


type alias FullCocktail =
    { id : String
    , name : String
    , thumbnail : String
    , ingredients : List Ingredient
    , instructions : String
    }



-- What kind of measurable quantity an ingredient has.
-- Determined at decode time by Api.parseMeasureToAmount.


type IngredientAmount
    = LiquidMl Float -- converted to ml: oz, cl, tsp, shot, dash, cup, etc.
    | PieceCount Float -- plain count: "3" limes, "5" mint leaves
    | UnknownAmount -- garnish ("Garnish with"), "Top", or unparsable measure



-- One ingredient of a cocktail.
-- measure keeps the raw API string for display in the Glossar and SVG.
-- amount is the parsed quantity, ready for shopping-list calculations.


type alias Ingredient =
    { name : String
    , measure : String
    , amount : IngredientAmount
    }



-- Loading state for a single category in the Glossar tree.


type CategoryState
    = Loading
    | Loaded (List CocktailSummary)
    | Failed



-- Loading state for the top-level list of category names.
-- Fetched once from list.php?c=list when the Glossar opens.


type CategoriesState
    = CategoriesNotLoaded
    | CategoriesLoading
    | CategoriesLoaded (List String)
    | CategoriesFailed



-- EVENT PLANNING
-- A cocktail bar event with a name, expected guest count, and a list of cocktails to serve.


type alias Event =
    { id : String
    , name : String
    , guestCount : Int
    , cocktails : List EventCocktail
    }



-- One cocktail entry inside an event: which cocktail and how many portions to serve.


type alias EventCocktail =
    { cocktailId : String
    , portions : Int
    }



-- MODEL
-- The full application state.


type alias Model =
    { key : Nav.Key -- needed to push URL changes (ADR-0003)
    , route : Route -- which top-level page is active
    , events : List Event -- all user-created events
    , activeEventId : Maybe String -- which event is open in the detail panel (Nothing = none)
    , nextEventId : Int -- monotonic counter for generating unique event IDs
    , eventFormName : String -- temporary: name field in the create/edit dialog
    , eventFormGuestCount : String -- temporary: guest count field (String so the input can bind directly)
    , eventSearchQuery : String -- text the user typed in the event cocktail search
    , eventSearchResults : List FullCocktail -- results from search.php for the event cocktail search
    , selectedCocktailId : Maybe String -- which cocktail detail panel is showing (Glossar)
    , cocktailCache : Dict String FullCocktail -- full recipes keyed by idDrink (ADR-0008)
    , categoriesState : CategoriesState -- loading state for the top-level category list
    , categories : Dict String CategoryState -- loading state per category name
    , selectedCategory : Maybe String -- which category is open in column 2 of the Glossar
    , searchQuery : String -- current text in the Glossar search box
    , glossarSearchResults : List FullCocktail -- results from search.php for the Glossar name-search
    , activeDialog : Dialog -- which modal is open (ADR-0002)
    , importText : String -- text in the Load dialog textarea
    , packageSizes : Dict String Float -- ingredient name → chosen package size in ml (default 700)
    , burgerOpen : Bool -- whether the mobile hamburger menu is expanded
    , eventFormError : Maybe String -- validation error shown in the create-event dialog
    , loadError : Maybe String -- parse error shown in the Load dialog when JSON is invalid
    }



-- MSG
-- All events the application can react to.
-- HTTP responses, user interactions, and URL changes all flow through here.


type Msg
    = -- URL events (ADR-0003)
      UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | NavigateTo Route
      -- Dialog controls (generic)
    | OpenDialog Dialog
    | CloseDialog
    | ImportTextChanged String
    | LoadProject
      -- HTTP responses for the Glossar
    | GotCategories (Result Http.Error (List String))
    | SelectCategory String
    | GotCocktailSummaries String (Result Http.Error (List CocktailSummary))
    | SelectCocktail String
    | GotFullCocktail (Result Http.Error FullCocktail)
      -- Event management (create, delete, duplicate, open)
    | OpenCreateEvent
    | EventFormNameChanged String
    | EventFormGuestCountChanged String
    | SaveEvent -- creates a new event from the modal form
    | DeleteEvent String -- event ID to remove from the list
    | DuplicateEvent String -- event ID to copy (appends " (Kopie)" to the name)
    | OpenEventDetail String -- event ID to show in the right panel
    | CloseEventDetail
    | SetEventName String String -- (eventId, newName) — inline edit in the detail panel
    | SetEventGuestCount String String -- (eventId, countStr) — inline edit in the detail panel
      -- Glossar name-search (bypasses category browsing)
    | GlossarSearchChanged String
    | GotGlossarSearchResults (Result Http.Error (List FullCocktail))
      -- Event cocktail management (search, add, remove, adjust portions)
    | EventSearchChanged String
    | SearchCocktailsForEvent
    | GotEventSearchResults (Result Http.Error (List FullCocktail))
    | AddCocktailToEvent String -- cocktailId to add (with portions = 1)
    | RemoveCocktailFromEvent String -- cocktailId to remove from the active event
    | SetPortions String Int -- (cocktailId, new portion count)
      -- Shopping list
    | SetPackageSize String Float -- (ingredientName, sizeInMl) — user selected a preset
      -- Mobile nav
    | ToggleBurger -- toggle the mobile navbar hamburger menu open/closed
      -- Navigate directly to an event's shopping list
    | OpenShoppingForEvent String -- activate event by ID, then push /einkaufsliste
