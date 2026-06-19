import gdav.{type Credentials}
import gdav/internal
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub type RequestBuilder {
  RequestBuilder(
    collection_path: String,
    filename: String,
    etag: String,
    icalstring: String,
  )
}

pub fn request(
  collection_path: String,
  filename: String,
  etag: String,
  icalstring: String,
) -> RequestBuilder {
  RequestBuilder(collection_path:, filename:, etag:, icalstring:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let headers = [
    #("Content-Type", "text/calendar; charset=utf-8"),
    #("If-Match", builder.etag),
  ]

  internal.request(
    credentials,
    http.Put,
    builder.collection_path <> "/" <> builder.filename,
    headers,
    builder.icalstring,
  )
}

pub fn response(res: Response(String)) -> Result(Nil, gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> Ok(Nil)
    412 -> Error(gdav.UnexpectedResponse(res))
    404 -> Error(gdav.NotFound)
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
