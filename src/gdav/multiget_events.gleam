import gdav.{type Credentials, type EventEntry, EventEntry}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/string

pub type RequestBuilder {
  RequestBuilder(collection_path: String, hrefs: List(String))
}

pub fn request(collection_path: String, hrefs: List(String)) -> RequestBuilder {
  RequestBuilder(collection_path:, hrefs:)
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
  let href_elements =
    list.map(builder.hrefs, fn(href) { "<d:href>" <> href <> "</d:href>" })
    |> string.join("")

  let body =
    "<c:calendar-multiget xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\">"
    <> "<d:prop>"
    <> "<d:getetag />"
    <> "<c:calendar-data />"
    <> "</d:prop>"
    <> href_elements
    <> "</c:calendar-multiget>"

  internal.request(
    credentials,
    http.Other("REPORT"),
    builder.collection_path,
    headers,
    body,
  )
}

pub fn response(
  res: Response(String),
) -> Result(List(EventEntry), gdav.DAVError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      let entries =
        xml.split_responses(res.body)
        |> list.filter_map(fn(block) {
          case
            xml.parse_first(block, "d:href"),
            xml.parse_first(block, "d:getetag"),
            xml.parse_first(block, "cal:calendar-data")
          {
            Ok(href), Ok(etag), Ok(data) -> Ok(EventEntry(href:, etag:, data:))
            _, _, _ -> Error(Nil)
          }
        })
      Ok(entries)
    }
    404 ->
      Error(
        gdav.UnexpectedResponseError(response.set_body(
          res,
          "Calendar not found",
        )),
      )
    401 | 403 -> Error(gdav.AuthenticationError("Authentication failed"))
    _ ->
      Error(gdav.UnexpectedXmlFormatError(
        "Unexpected HTTP status: " <> int.to_string(res.status),
      ))
  }
}
