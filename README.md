# gdav
CalDAV and CardDAV client for Gleam

[![Package Version](https://img.shields.io/hexpm/v/gdav)](https://hex.pm/packages/gdav)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gdav/)

This package uses the sans-io approach, meaning it does not send HTTP requests itself, instead it gives you functions for creating HTTP requests for and decoding HTTP responses from a DAV API, and you send the requests with a HTTP client of your choosing.

This HTTP client independence gives you full control over HTTP, and means this library can be used on both the Erlang and JavaScript runtimes.

```sh
gleam add gdav@1
```
```gleam
import gdav
import gdav/get_all_events
import gleam/hackney

pub fn main() {
  let creds =
    gdav.credentials("http://dav-api-host:port/dav.php")
    |> gdav.with_basic_auth("YOUR_USERNAME", "YOUR_PASSWORD")

  let request =
    get_all_events.request("YOUR_USERNAME", "CALENDAR_NAME")
    |> get_all_events.build(creds)

  let assert Ok(res) = hackney.send(request)

  let assert Ok(calendar_data) = get_all_events.response(res) // a list containing strings of calendar data
}
```

Further documentation can be found at <https://hexdocs.pm/gdav>.
