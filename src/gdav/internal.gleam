import gdav.{type Credentials}
import gleam/http
import gleam/http/request.{type Request, Request}
import gleam/option
import gleam/result

pub fn request(
  credentials: Credentials,
  method: http.Method,
  path: String,
  headers: List(#(String, String)),
  body: String,
) -> Request(String) {
  let request =
    Request(
      method:,
      headers:,
      body:,
      scheme: result.unwrap(
        http.scheme_from_string(option.unwrap(credentials.scheme, "https")),
        http.Https,
      ),
      host: option.unwrap(credentials.host, ""),
      port: credentials.port,
      path:,
      query: option.None,
    )

  request
  |> request.prepend_header(
    "Authorization",
    option.unwrap(credentials.auth_header, ""),
  )
}
