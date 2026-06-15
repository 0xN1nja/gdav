import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int

pub type RequestBuilder {
  RequestBuilder(principal_path: String)
}

pub fn request(principal_path: String) -> RequestBuilder {
  RequestBuilder(principal_path:)
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
    "<d:propfind xmlns:d=\"DAV:\" xmlns:card=\"urn:ietf:params:xml:ns:carddav\">"
    <> "<d:prop>"
    <> "<card:addressbook-home-set />"
    <> "</d:prop>"
    <> "</d:propfind>"

  internal.request(
    credentials,
    http.Other("PROPFIND"),
    builder.principal_path,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(String, gdav.DAVError) {
  case res.status {
    s if s >= 200 && s < 300 ->
      xml.parse_nested_href(res.body, "card:addressbook-home-set")
    401 | 403 -> Error(gdav.AuthenticationError("Authentication failed"))
    _ ->
      Error(gdav.UnexpectedXmlFormatError(
        "Unexpected HTTP status: " <> int.to_string(res.status),
      ))
  }
}
