import gleam/bit_array
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/uri

pub type DAVError {
  AuthenticationError(String)
  XmlParseError(String)
  UnexpectedXmlFormatError(String)
  UnexpectedResponseError(Response(String))
}

pub type Credentials {
  Credentials(
    scheme: Option(String),
    port: Option(Int),
    host: Option(String),
    path: String,
    auth_header: Option(String),
  )
}

pub fn credentials(base_url: String) {
  let assert Ok(parsed_uri) = uri.parse(base_url)

  Credentials(
    scheme: parsed_uri.scheme,
    host: parsed_uri.host,
    port: parsed_uri.port,
    path: parsed_uri.path,
    auth_header: None,
  )
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
