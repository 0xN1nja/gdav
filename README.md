# gdav

A sans-io CalDAV and CardDAV client library for Gleam.

[![Package Version](https://img.shields.io/hexpm/v/gdav)](https://hex.pm/packages/gdav)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gdav/)

This package uses the _sans-io_ approach, meaning it does not send HTTP requests
itself. Instead it gives you functions for building HTTP requests and decoding
HTTP responses, and you send the requests with an HTTP client of your choosing.

This HTTP client independence gives you full control over HTTP, and means this
library works on both the Erlang and JavaScript runtimes.

```sh
gleam add gdav@1
```

## Authentication

**Basic** — username and password, works with most self-hosted servers:

```gleam
let creds =
  gdav.credentials("https://dav.example.com/")
  |> gdav.with_basic_auth("username", "password")
```

**Bearer** — OAuth2 access token, required for Google Calendar, Fastmail, and other hosted providers:

```gleam
let creds =
  gdav.credentials("https://dav.example.com/")
  |> gdav.with_bearer_auth("your_oauth_access_token")
```

## Quickstart — known collection path

If you already know your collection URL (typical for self-hosted servers like
Radicale, Baikal, DaviCal, Nextcloud), skip discovery and go straight to
operations:

```gleam
import gdav
import gdav/get_all_events
import gleam/hackney
import gleam/io

pub fn main() {
  let creds =
    gdav.credentials("http://localhost:port/")
    |> gdav.with_basic_auth("admin", "admin")

  let assert Ok(res) =
    get_all_events.request("/admin/my-calendar-uuid")
    |> get_all_events.build(creds)
    |> hackney.send

  let assert Ok(events) = get_all_events.response(res)
  io.debug(events)
}
```

## Discovery — finding URLs automatically

For servers where you only know the base URL, use the discovery chain to find
the principal and home URLs, then list collections.

```gleam
import gdav
import gdav/discover_principal
import gdav/discover_calendar_home
import gdav/list_calendars
import gdav/get_all_events
import gleam/hackney

pub fn main() {
  let creds =
    gdav.credentials("https://dav.example.com/dav.php")
    |> gdav.with_basic_auth("username", "password")

  // Step 1: find the user's principal URL
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(creds)
    |> hackney.send
  let assert Ok(principal) = discover_principal.response(res)

  // Step 2: find the calendar home URL
  let assert Ok(res) =
    discover_calendar_home.request(principal)
    |> discover_calendar_home.build(creds)
    |> hackney.send
  let assert Ok(home) = discover_calendar_home.response(res)

  // Step 3: list all calendars
  let assert Ok(res) =
    list_calendars.request(home)
    |> list_calendars.build(creds)
    |> hackney.send
  let assert Ok(calendars) = list_calendars.response(res)

  // Step 4: use a calendar's href for operations
  let assert [calendar, ..] = calendars
  let assert Ok(res) =
    get_all_events.request(calendar.href)
    |> get_all_events.build(creds)
    |> hackney.send
  let assert Ok(events) = get_all_events.response(res)
}
```

### Service discovery (.well-known)

For hosted providers (Google Calendar, Apple Calendar) the actual CalDAV
endpoint differs from the server's main domain. Use `discover_service` to probe
`/.well-known/caldav` and follow the redirect to the real root URL.

```gleam
import gdav/discover_service

let assert Ok(res) =
  discover_service.request(discover_service.CalDAV)
  |> discover_service.build(creds)
  |> hackney.send

let root_path = case discover_service.response(res) {
  Ok(discover_service.Redirected(url)) -> url
  _ -> creds.path
}

let assert Ok(res) =
  discover_principal.request_at(root_path)
  |> discover_principal.build(creds)
  |> hackney.send
```

For self-hosted servers this step is usually unnecessary — they either don't
expose `/.well-known` or it points straight back to the URL you already have.

## CalDAV operations

- `create_event` — Create a calendar event
- `get_event` — Fetch a single calendar event
- `update_event` — Update a calendar event (requires current etag)
- `delete_event` — Delete a calendar event
- `get_all_events` — Fetch all events with their data in one request
- `get_etags` — Fetch href/etag pairs for all events (for change detection)
- `multiget_events` — Fetch specific events by URL in one request
- `get_calendar_info` — Fetch calendar metadata (displayname, ctag, sync-token)
- `list_calendars` — List all calendars under a calendar home URL
- `discover_calendar_home` — Discover the calendar home URL from a principal URL
- `discover_principal` — Discover the current user's principal URL

## CardDAV operations

- `create_contact` — Create a vCard contact
- `get_contact` — Fetch a single contact
- `update_contact` — Update a contact (requires current etag)
- `delete_contact` — Delete a contact
- `get_all_contacts` — Fetch all contacts with their data in one request
- `get_contact_etags` — Fetch href/etag pairs for all contacts (for change detection)
- `multiget_contacts` — Fetch specific contacts by URL in one request
- `get_addressbook_info` — Fetch addressbook metadata (displayname, ctag, sync-token)
- `list_addressbooks` — List all addressbooks under an addressbook home URL
- `discover_addressbook_home` — Discover the addressbook home URL from a principal URL

## Shared operations

- `sync_collection` — Fetch changes since a sync-token (WebDAV-Sync, works for both calendars and addressbooks)
- `discover_service` — Probe `/.well-known/caldav` or `/.well-known/carddav` for service discovery

Further documentation can be found at <https://hexdocs.pm/gdav>.
