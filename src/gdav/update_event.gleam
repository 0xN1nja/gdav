import gdav.{type Credentials}
import gdav/internal
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int

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

pub fn response(res: Response(String)) -> Result(Nil, gdav.DAVError) {
  case res.status {
    s if s >= 200 && s < 300 -> Ok(Nil)
    412 ->
      Error(
        gdav.UnexpectedResponseError(response.set_body(
          res,
          "Precondition failed: etag mismatch",
        )),
      )
    404 ->
      Error(gdav.UnexpectedResponseError(response.set_body(res, "Not found")))
    401 | 403 -> Error(gdav.AuthenticationError("Authentication failed"))
    _ ->
      Error(gdav.UnexpectedXmlFormatError(
        "Unexpected HTTP status: " <> int.to_string(res.status),
      ))
  }
}
