import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list

pub type Calendar {
  Calendar(href: String, displayname: String, ctag: String)
}

pub type RequestBuilder {
  RequestBuilder(calendar_home_path: String)
}

pub fn request(calendar_home_path: String) -> RequestBuilder {
  RequestBuilder(calendar_home_path:)
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
    "<d:propfind xmlns:d=\"DAV:\" xmlns:cs=\"http://calendarserver.org/ns/\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\">"
    <> "<d:prop>"
    <> "<d:resourcetype />"
    <> "<d:displayname />"
    <> "<cs:getctag />"
    <> "<c:supported-calendar-component-set />"
    <> "</d:prop>"
    <> "</d:propfind>"

  internal.request(
    credentials,
    http.Other("PROPFIND"),
    builder.calendar_home_path,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(List(Calendar), gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      let calendars =
        xml.split_responses(res.body)
        |> list.filter_map(fn(block) {
          case
            xml.parse_first(block, "d:href"),
            xml.parse_first(block, "d:displayname"),
            xml.parse_first(block, "cs:getctag")
          {
            Ok(href), Ok(displayname), Ok(ctag) ->
              Ok(Calendar(href:, displayname:, ctag:))
            _, _, _ -> Error(Nil)
          }
        })
      Ok(calendars)
    }
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
