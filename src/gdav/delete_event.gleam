import gdav.{type Credentials}
import gdav/internal
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}

pub type RequestBuilder {
  RequestBuilder(
    collection_path: String,
    filename: String,
    etag: Option(String),
  )
}

pub fn request(collection_path: String, filename: String) -> RequestBuilder {
  RequestBuilder(collection_path:, filename:, etag: None)
}

pub fn with_etag(builder: RequestBuilder, etag: String) -> RequestBuilder {
  RequestBuilder(..builder, etag: Some(etag))
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let headers = case builder.etag {
    Some(etag) -> [#("If-Match", etag)]
    None -> []
  }

  internal.request(
    credentials,
    http.Delete,
    builder.collection_path <> "/" <> builder.filename,
    headers,
    "",
  )
}

pub fn response(res: Response(String)) -> Result(Nil, gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> Ok(Nil)
    404 -> Error(gdav.NotFound)
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
