import gdav
import gdav/internal/xml
import gleeunit/should
import xmlm

pub fn empty_multistatus_test() {
  let body = "<?xml version=\"1.0\"?>" <> "<d:multistatus xmlns:d=\"DAV:\"/>"
  xml.parse_multistatus(body)
  |> should.equal(Ok([]))
}

pub fn single_response_displayname_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\" xmlns:cs=\"http://calendarserver.org/ns/\">"
    <> "<d:response>"
    <> "<d:href>/cal/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop>"
    <> "<d:displayname>My Calendar</d:displayname>"
    <> "<cs:getctag>abc123</cs:getctag>"
    <> "</d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  let assert Ok([r]) = xml.parse_multistatus(body)
  r.href |> should.equal("/cal/")
  r.status_code |> should.equal(200)
  xml.find_text(r.properties, xml.ns_dav, "displayname")
  |> should.equal(Ok("My Calendar"))
  xml.find_text(r.properties, xml.ns_cs, "getctag")
  |> should.equal(Ok("abc123"))
}

pub fn namespace_prefix_independence_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<D:multistatus xmlns:D=\"DAV:\">"
    <> "<D:response>"
    <> "<D:href>/x/</D:href>"
    <> "<D:propstat>"
    <> "<D:prop><D:displayname>Test</D:displayname></D:prop>"
    <> "<D:status>HTTP/1.1 200 OK</D:status>"
    <> "</D:propstat>"
    <> "</D:response>"
    <> "</D:multistatus>"
  let assert Ok([r]) = xml.parse_multistatus(body)
  xml.find_text(r.properties, xml.ns_dav, "displayname")
  |> should.equal(Ok("Test"))
}

pub fn multiple_propstat_only_200_included_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/r/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:displayname>Present</d:displayname></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "<d:propstat>"
    <> "<d:prop><d:sync-token/></d:prop>"
    <> "<d:status>HTTP/1.1 404 Not Found</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  let assert Ok([r]) = xml.parse_multistatus(body)
  xml.find_text(r.properties, xml.ns_dav, "displayname")
  |> should.equal(Ok("Present"))
  xml.find_text(r.properties, xml.ns_dav, "sync-token")
  |> should.equal(Error(Nil))
}

pub fn self_closing_property_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/r/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:sync-token/></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  let assert Ok([r]) = xml.parse_multistatus(body)
  xml.find_text(r.properties, xml.ns_dav, "sync-token")
  |> should.equal(Ok(""))
}

pub fn multiple_responses_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/a/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:displayname>A</d:displayname></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "<d:response>"
    <> "<d:href>/b/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:displayname>B</d:displayname></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  let assert Ok(responses) = xml.parse_multistatus(body)
  responses
  |> should.equal([
    xml.DavResponse(href: "/a/", status_code: 200, properties: [
      xml.TextProp(xmlm_name(xml.ns_dav, "displayname"), "A"),
    ]),
    xml.DavResponse(href: "/b/", status_code: 200, properties: [
      xml.TextProp(xmlm_name(xml.ns_dav, "displayname"), "B"),
    ]),
  ])
}

pub fn sync_report_token_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/cal/event.ics</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:getetag>\"etag1\"</d:getetag></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "<d:sync-token>http://example.com/ns/sync/10</d:sync-token>"
    <> "</d:multistatus>"
  let assert Ok(#(responses, token)) = xml.parse_sync_report(body)
  token |> should.equal("http://example.com/ns/sync/10")
  let assert [r] = responses
  xml.find_text(r.properties, xml.ns_dav, "getetag")
  |> should.equal(Ok("\"etag1\""))
}

pub fn sync_report_deleted_item_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/cal/deleted.ics</d:href>"
    <> "<d:status>HTTP/1.1 404 Not Found</d:status>"
    <> "</d:response>"
    <> "<d:sync-token>tok2</d:sync-token>"
    <> "</d:multistatus>"
  let assert Ok(#(responses, _)) = xml.parse_sync_report(body)
  let assert [r] = responses
  r.href |> should.equal("/cal/deleted.ics")
  r.status_code |> should.equal(404)
  r.properties |> should.equal([])
}

pub fn parse_single_value_principal_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop>"
    <> "<d:current-user-principal>"
    <> "<d:href>/principals/user/</d:href>"
    <> "</d:current-user-principal>"
    <> "</d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  xml.parse_single_value(body, xmlm_name(xml.ns_dav, "current-user-principal"))
  |> should.equal(Ok("/principals/user/"))
}

pub fn parse_single_value_calendar_home_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\" xmlns:cal=\"urn:ietf:params:xml:ns:caldav\">"
    <> "<d:response>"
    <> "<d:href>/p/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop>"
    <> "<cal:calendar-home-set><d:href>/calendars/user/</d:href></cal:calendar-home-set>"
    <> "</d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  xml.parse_single_value(body, xmlm_name(xml.ns_caldav, "calendar-home-set"))
  |> should.equal(Ok("/calendars/user/"))
}

pub fn parse_single_value_missing_test() {
  let body =
    "<?xml version=\"1.0\"?>"
    <> "<d:multistatus xmlns:d=\"DAV:\">"
    <> "<d:response>"
    <> "<d:href>/</d:href>"
    <> "<d:propstat>"
    <> "<d:prop><d:displayname>x</d:displayname></d:prop>"
    <> "<d:status>HTTP/1.1 200 OK</d:status>"
    <> "</d:propstat>"
    <> "</d:response>"
    <> "</d:multistatus>"
  xml.parse_single_value(body, xmlm_name(xml.ns_dav, "current-user-principal"))
  |> should.equal(
    Error(gdav.XmlParseError("Property not found: current-user-principal")),
  )
}

pub fn malformed_xml_returns_error_test() {
  let body = "<not valid xml <<<"
  case xml.parse_multistatus(body) {
    Error(gdav.XmlParseError(_)) -> should.be_ok(Ok(Nil))
    other -> should.be_ok(Error(other))
  }
}

fn xmlm_name(uri: String, local: String) -> xmlm.Name {
  xmlm.Name(uri, local)
}
