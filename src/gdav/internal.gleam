import gdav.{type Credentials}
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/option

pub fn request(
  credentials: Credentials,
  method: http.Method,
  path: String,
  headers: List(#(String, String)),
  body: String,
) -> Request(String) {
  let req =
    Request(
      method:,
      headers:,
      body:,
      scheme: credentials.scheme,
      host: credentials.host,
      port: credentials.port,
      path:,
      query: option.None,
    )

  case credentials.auth_header {
    option.None -> req
    option.Some(auth) -> request.prepend_header(req, "Authorization", auth)
  }
}
