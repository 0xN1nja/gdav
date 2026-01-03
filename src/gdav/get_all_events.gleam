import gdav.{type Credentials}
import gdav/internal
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub type RequestBuilder {
  RequestBuilder(user: String, calendar_name: String)
}

pub type Outcome(body) {
  Found(body)
  NotFound
}

pub fn request(user: String, calendar_name: String) -> RequestBuilder {
  RequestBuilder(user:, calendar_name:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let headers = [
    #("Depth", "1"),
    #("Prefer", "return-minimal"),
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<c:calendar-query xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\">"
    <> "<d:prop>"
    <> " <d:getetag />"
    <> "<c:calendar-data />"
    <> "</d:prop>"
    <> "<c:filter>"
    <> "<c:comp-filter name=\"VCALENDAR\" />"
    <> "</c:filter>"
    <> "</c:calendar-query>"

  internal.request(
    credentials,
    http.Other("REPORT"),
    credentials.path
      <> "/"
      <> "calendars"
      <> "/"
      <> builder.user
      <> "/"
      <> builder.calendar_name,
    headers,
    body,
  )
}

pub fn response(
  response: Response(body),
) -> Result(Outcome(body), gdav.DAVError) {
  case response.status {
    207 -> Ok(Found(response.body))
    404 -> Ok(NotFound)
    _ -> Error(gdav.UnexpectedResponseError(response.set_body(response, "")))
  }
}
