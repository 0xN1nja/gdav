import gdav.{type ContactEntry, type Credentials, ContactEntry}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
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
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let href_elements =
    list.map(builder.hrefs, fn(href) { "<d:href>" <> href <> "</d:href>" })
    |> string.join("")

  let body =
    "<card:addressbook-multiget xmlns:d=\"DAV:\" xmlns:card=\"urn:ietf:params:xml:ns:carddav\">"
    <> "<d:prop>"
    <> "<d:getetag />"
    <> "<card:address-data />"
    <> "</d:prop>"
    <> href_elements
    <> "</card:addressbook-multiget>"

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
) -> Result(List(ContactEntry), gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      use responses <- result.try(xml.parse_multistatus(res.body))
      let entries =
        list.filter_map(responses, fn(r) {
          let find = fn(ns, local) { xml.find_text(r.properties, ns, local) }
          case
            find(xml.ns_dav, "getetag"),
            find(xml.ns_carddav, "address-data")
          {
            Ok(etag), Ok(data) -> Ok(ContactEntry(href: r.href, etag:, data:))
            _, _ -> Error(Nil)
          }
        })
      Ok(entries)
    }
    404 -> Error(gdav.NotFound)
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
