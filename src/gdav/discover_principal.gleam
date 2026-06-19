import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option

pub type RequestBuilder {
  RequestBuilder(path: option.Option(String))
}

pub fn request() -> RequestBuilder {
  RequestBuilder(path: option.None)
}

pub fn request_at(path: String) -> RequestBuilder {
  RequestBuilder(path: option.Some(path))
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let path = option.unwrap(builder.path, credentials.path)
  let headers = [
    #("Depth", "0"),
    #("Content-Type", "application/xml; charset=utf-8"),
  ]
  let body =
    "<d:propfind xmlns:d=\"DAV:\">"
    <> "<d:prop>"
    <> "<d:current-user-principal />"
    <> "</d:prop>"
    <> "</d:propfind>"

  internal.request(credentials, http.Other("PROPFIND"), path, headers, body)
}

pub fn response(res: Response(String)) -> Result(String, gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 ->
      xml.parse_nested_href(res.body, "d:current-user-principal")
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
