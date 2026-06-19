import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result

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
) -> Result(List(Addressbook), gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      use responses <- result.try(xml.parse_multistatus(res.body))
      let addressbooks =
        list.filter_map(responses, fn(r) {
          let find = fn(ns, local) { xml.find_text(r.properties, ns, local) }
          case find(xml.ns_dav, "displayname"), find(xml.ns_cs, "getctag") {
            Ok(displayname), Ok(ctag) ->
              Ok(Addressbook(href: r.href, displayname:, ctag:))
            _, _ -> Error(Nil)
          }
        })
      Ok(addressbooks)
    }
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
