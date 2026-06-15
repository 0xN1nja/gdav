import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list

pub type Addressbook {
  Addressbook(href: String, displayname: String, ctag: String)
}

pub type RequestBuilder {
  RequestBuilder(addressbook_home_path: String)
}

pub fn request(addressbook_home_path: String) -> RequestBuilder {
  RequestBuilder(addressbook_home_path:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let headers = [
    #("Depth", "1"),
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<d:propfind xmlns:d=\"DAV:\" xmlns:cs=\"http://calendarserver.org/ns/\">"
    <> "<d:prop>"
    <> "<d:resourcetype />"
    <> "<d:displayname />"
    <> "<cs:getctag />"
    <> "</d:prop>"
    <> "</d:propfind>"

  internal.request(
    credentials,
    http.Other("PROPFIND"),
    builder.addressbook_home_path,
    headers,
    body,
  )
}

pub fn response(
  res: Response(String),
) -> Result(List(Addressbook), gdav.DAVError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      let addressbooks =
        xml.split_responses(res.body)
        |> list.filter_map(fn(block) {
          case
            xml.parse_first(block, "d:href"),
            xml.parse_first(block, "d:displayname"),
            xml.parse_first(block, "cs:getctag")
          {
            Ok(href), Ok(displayname), Ok(ctag) ->
              Ok(Addressbook(href:, displayname:, ctag:))
            _, _, _ -> Error(Nil)
          }
        })
      Ok(addressbooks)
    }
    401 | 403 -> Error(gdav.AuthenticationError("Authentication failed"))
    _ ->
      Error(gdav.UnexpectedXmlFormatError(
        "Unexpected HTTP status: " <> int.to_string(res.status),
      ))
  }
}
