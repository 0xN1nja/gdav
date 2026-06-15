import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int

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
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<card:addressbook-query xmlns:d=\"DAV:\" xmlns:card=\"urn:ietf:params:xml:ns:carddav\">"
    <> "<d:prop>"
    <> "<d:getetag />"
    <> "<card:address-data />"
    <> "</d:prop>"
    <> "</card:addressbook-query>"

  internal.request(
    credentials,
    http.Other("REPORT"),
    builder.collection_path,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(List(String), gdav.DAVError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      let parser = xml.element(res.body, "card:address-data")
      xml.parse_element(parser)
    }
    404 ->
      Error(
        gdav.UnexpectedResponseError(response.set_body(
          res,
          "Addressbook not found",
        )),
      )
    401 | 403 -> Error(gdav.AuthenticationError("Authentication failed"))
    _ ->
      Error(gdav.UnexpectedXmlFormatError(
        "Unexpected HTTP status: " <> int.to_string(res.status),
      ))
  }
}
