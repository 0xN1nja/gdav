import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/result

pub type AddressbookInfo {
  AddressbookInfo(displayname: String, ctag: String, sync_token: Option(String))
}

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
    #("Depth", "0"),
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<d:propfind xmlns:d=\"DAV:\" xmlns:cs=\"http://calendarserver.org/ns/\">"
    <> "<d:prop>"
    <> "<d:displayname />"
    <> "<cs:getctag />"
    <> "<d:sync-token />"
    <> "</d:prop>"
    <> "</d:propfind>"

  internal.request(
    credentials,
    http.Other("PROPFIND"),
    builder.collection_path,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(AddressbookInfo, gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      use r <- result.try(xml.parse_propfind(res.body))
      let find = fn(ns, local) { xml.find_text(r.properties, ns, local) }
      case find(xml.ns_dav, "displayname"), find(xml.ns_cs, "getctag") {
        Ok(displayname), Ok(ctag) -> {
          let sync_token = case find(xml.ns_dav, "sync-token") {
            Ok(t) if t != "" -> Some(t)
            _ -> None
          }
          Ok(AddressbookInfo(displayname:, ctag:, sync_token:))
        }
        Error(_), _ -> Error(gdav.CouldNotParseXml("Missing displayname"))
        _, Error(_) -> Error(gdav.CouldNotParseXml("Missing ctag"))
      }
    }
    404 -> Error(gdav.NotFound)
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
