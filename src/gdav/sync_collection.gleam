import gdav.{type Credentials}
import gdav/internal
import gdav/internal/xml
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result

pub type SyncResult {
  SyncResult(
    changed: List(#(String, String)),
    deleted: List(String),
    sync_token: String,
  )
}

pub type RequestBuilder {
  RequestBuilder(collection_path: String, sync_token: String)
}

pub fn request(collection_path: String, sync_token: String) -> RequestBuilder {
  RequestBuilder(collection_path:, sync_token:)
}

pub fn build(
  builder: RequestBuilder,
  credentials: Credentials,
) -> Request(String) {
  let headers = [#("Content-Type", "application/xml; charset=utf-8")]
  let body =
    "<?xml version=\"1.0\" encoding=\"utf-8\" ?>"
    <> "<d:sync-collection xmlns:d=\"DAV:\">"
    <> "<d:sync-token>"
    <> builder.sync_token
    <> "</d:sync-token>"
    <> "<d:sync-level>1</d:sync-level>"
    <> "<d:prop><d:getetag/></d:prop>"
    <> "</d:sync-collection>"

  internal.request(
    credentials,
    http.Other("REPORT"),
    builder.collection_path,
    headers,
    body,
  )
}

pub fn response(res: Response(String)) -> Result(SyncResult, gdav.DavError) {
  case res.status {
    s if s >= 200 && s < 300 -> {
      use #(responses, sync_token) <- result.try(xml.parse_sync_report(res.body))

      let changed =
        list.filter_map(responses, fn(r) {
          case xml.find_text(r.properties, xml.ns_dav, "getetag") {
            Ok(etag) if etag != "" -> Ok(#(r.href, etag))
            _ -> Error(Nil)
          }
        })

      let deleted =
        list.filter_map(responses, fn(r) {
          case r.status_code {
            404 -> Ok(r.href)
            _ -> Error(Nil)
          }
        })

      Ok(SyncResult(changed:, deleted:, sync_token:))
    }
    401 | 403 -> Error(gdav.AuthenticationFailed)
    _ -> Error(gdav.UnexpectedResponse(res))
  }
}
