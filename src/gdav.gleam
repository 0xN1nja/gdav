import gleam/bit_array
import gleam/http
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri

pub type DavError {
  AuthenticationFailed
  NotFound
  XmlParseError(String)
  UnexpectedResponse(Response(String))
}

pub type Credentials {
  Credentials(
    scheme: http.Scheme,
    port: Option(Int),
    host: String,
    path: String,
    auth_header: Option(String),
  )
}

pub fn credentials(base_url: String) -> Result(Credentials, Nil) {
  use parsed_uri <- result.try(uri.parse(base_url))
  use scheme_str <- result.try(option.to_result(parsed_uri.scheme, Nil))
  use scheme <- result.try(http.scheme_from_string(scheme_str))
  use host <- result.try(option.to_result(parsed_uri.host, Nil))
  Ok(Credentials(
    scheme:,
    host:,
    port: parsed_uri.port,
    path: parsed_uri.path,
    auth_header: None,
  ))
}

pub fn with_basic_auth(
  credentials: Credentials,
  username: String,
  password: String,
) -> Credentials {
  let auth_header =
    "Basic"
    <> " "
    <> bit_array.base64_encode(<<username:utf8, ":":utf8, password:utf8>>, True)

  Credentials(..credentials, auth_header: Some(auth_header))
}

pub fn with_bearer_auth(credentials: Credentials, token: String) -> Credentials {
  Credentials(..credentials, auth_header: Some("Bearer " <> token))
}

pub type EventEntry {
  EventEntry(href: String, etag: String, data: String)
}

pub type ContactEntry {
  ContactEntry(href: String, etag: String, data: String)
}
