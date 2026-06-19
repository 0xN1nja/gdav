import gdav.{type Credentials}
import gdav/internal
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/string

pub type AccountType {
  CalDAV
  CardDAV
}

pub type DiscoveryResult {
  Redirected(to: String)
  Confirmed
}

pub type RequestBuilder {
  RequestBuilder(account_type: AccountType)
}

pub fn request(account_type: AccountType) -> RequestBuilder {
  RequestBuilder(account_type:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let well_known = case builder.account_type {
    CalDAV -> "/.well-known/caldav"
    CardDAV -> "/.well-known/carddav"
  }
  let headers = [
    #("Depth", "0"),
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<d:propfind xmlns:d=\"DAV:\"><d:prop><d:resourcetype/></d:prop></d:propfind>"
  internal.request(
    credentials,
    http.Other("PROPFIND"),
    well_known,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(DiscoveryResult, gdav.DavError) {
  case res.status {
    s if s >= 300 && s < 400 -> {
      case
        list.find(res.headers, fn(h) { string.lowercase(h.0) == "location" })
      {
        Ok(#(_, url)) -> Ok(Redirected(url))
        Error(_) -> Error(gdav.UnexpectedResponse(res))
      }
    }
    s if s >= 200 && s < 300 -> Ok(Confirmed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
