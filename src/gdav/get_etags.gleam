import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result

pub type RequestBuilder {
  RequestBuilder(collection_path: String)
}

pub fn request(collection_path: String) -> RequestBuilder {
  RequestBuilder(collection_path:)
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
    <> "<d:getetag />"
    <> "</d:prop>"
    <> "<c:filter>"
    <> "<c:comp-filter name=\"VCALENDAR\" />"
    <> "</c:filter>"
    <> "</c:calendar-query>"

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
) -> Result(List(#(String, String)), gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      use responses <- result.try(xml.parse_multistatus(res.body))
      let pairs =
        list.filter_map(responses, fn(r) {
          case xml.find_text(r.properties, xml.ns_dav, "getetag") {
            Ok(etag) if etag != "" -> Ok(#(r.href, etag))
            _ -> Error(Nil)
          }
        })
      Ok(pairs)
    }
    404 -> Error(gdav.NotFound)
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
