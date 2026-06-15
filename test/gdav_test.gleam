import gdav/create_contact
import gdav/create_event
import gdav/delete_contact
import gdav/delete_event
import gdav/discover_addressbook_home
import gdav/discover_calendar_home
import gdav/discover_principal
import gdav/get_addressbook_info
import gdav/get_all_contacts
import gdav/get_all_events
import gdav/get_calendar_info
import gdav/get_contact
import gdav/get_contact_etags
import gdav/get_etags
import gdav/get_event
import gdav/list_addressbooks
import gdav/list_calendars
import gdav/multiget_contacts
import gdav/multiget_events
import gdav/sync_collection
import gdav/update_contact
import gdav/update_event
import gleam/hackney
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import helpers

pub fn main() {
  gleeunit.main()
}

// CalDAV

pub fn caldav_discover_principal_test() {
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(helpers.creds())
    |> hackney.send
  let assert Ok(path) = discover_principal.response(res)
  path |> should.not_equal("")
}

pub fn caldav_discover_calendar_home_test() {
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(helpers.creds())
    |> hackney.send
  let assert Ok(principal) = discover_principal.response(res)
  let assert Ok(res) =
    discover_calendar_home.request(principal)
    |> discover_calendar_home.build(helpers.creds())
    |> hackney.send
  let assert Ok(home) = discover_calendar_home.response(res)
  home |> should.not_equal("")
}

pub fn caldav_list_calendars_test() {
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(helpers.creds())
    |> hackney.send
  let assert Ok(principal) = discover_principal.response(res)
  let assert Ok(res) =
    discover_calendar_home.request(principal)
    |> discover_calendar_home.build(helpers.creds())
    |> hackney.send
  let assert Ok(home) = discover_calendar_home.response(res)
  let assert Ok(res) =
    list_calendars.request(home)
    |> list_calendars.build(helpers.creds())
    |> hackney.send
  let assert Ok(calendars) = list_calendars.response(res)
  list.is_empty(calendars) |> should.be_false
}

pub fn caldav_get_calendar_info_test() {
  let assert Ok(res) =
    get_calendar_info.request(helpers.calendar_collection_path)
    |> get_calendar_info.build(helpers.creds())
    |> hackney.send
  let assert Ok(info) = get_calendar_info.response(res)
  info.displayname |> should.not_equal("")
  info.ctag |> should.not_equal("")
}

pub fn caldav_create_event_test() {
  helpers.cleanup_event()
  let assert Ok(res) =
    create_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
      helpers.test_icalstring,
    )
    |> create_event.build(helpers.creds())
    |> hackney.send
  let assert Ok(_) = create_event.response(res)
}

pub fn caldav_get_event_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    get_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
    )
    |> get_event.build(helpers.creds())
    |> hackney.send
  let assert Ok(ical) = get_event.response(res)
  string.contains(ical, "gdav Test Event") |> should.be_true
}

pub fn caldav_get_event_not_found_test() {
  helpers.cleanup_event()
  let assert Ok(res) =
    get_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
    )
    |> get_event.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = get_event.response(res)
}

pub fn caldav_get_all_events_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    get_all_events.request(helpers.calendar_collection_path)
    |> get_all_events.build(helpers.creds())
    |> hackney.send
  let assert Ok(events) = get_all_events.response(res)
  list.is_empty(events) |> should.be_false
}

pub fn caldav_get_etags_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    get_etags.request(helpers.calendar_collection_path)
    |> get_etags.build(helpers.creds())
    |> hackney.send
  let assert Ok(pairs) = get_etags.response(res)
  list.is_empty(pairs) |> should.be_false
}

pub fn caldav_update_event_test() {
  helpers.cleanup_event()
  let etag = helpers.create_test_event()
  let assert Ok(res) =
    update_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
      etag,
      helpers.updated_icalstring,
    )
    |> update_event.build(helpers.creds())
    |> hackney.send
  let assert Ok(Nil) = update_event.response(res)
  let assert Ok(res) =
    get_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
    )
    |> get_event.build(helpers.creds())
    |> hackney.send
  let assert Ok(ical) = get_event.response(res)
  string.contains(ical, "gdav Test Event Updated") |> should.be_true
}

pub fn caldav_update_event_stale_etag_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    update_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
      "wrong-etag",
      helpers.updated_icalstring,
    )
    |> update_event.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = update_event.response(res)
}

pub fn caldav_multiget_events_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    multiget_events.request(helpers.calendar_collection_path, [
      helpers.test_event_path,
    ])
    |> multiget_events.build(helpers.creds())
    |> hackney.send
  let assert Ok(entries) = multiget_events.response(res)
  let assert [entry] = entries
  string.contains(entry.data, "gdav Test Event") |> should.be_true
}

pub fn caldav_sync_collection_test() {
  helpers.cleanup_event()
  let assert Ok(res) =
    get_calendar_info.request(helpers.calendar_collection_path)
    |> get_calendar_info.build(helpers.creds())
    |> hackney.send
  let assert Ok(info) = get_calendar_info.response(res)
  let token_before = case info.sync_token {
    Some(t) -> t
    None -> ""
  }

  let _etag = helpers.create_test_event()

  let assert Ok(res) =
    sync_collection.request(helpers.calendar_collection_path, token_before)
    |> sync_collection.build(helpers.creds())
    |> hackney.send
  let assert Ok(sync1) = sync_collection.response(res)
  list.is_empty(sync1.changed) |> should.be_false

  helpers.cleanup_event()

  let assert Ok(res) =
    sync_collection.request(helpers.calendar_collection_path, sync1.sync_token)
    |> sync_collection.build(helpers.creds())
    |> hackney.send
  let assert Ok(sync2) = sync_collection.response(res)
  list.is_empty(sync2.deleted) |> should.be_false
}

pub fn caldav_delete_event_test() {
  helpers.cleanup_event()
  let _etag = helpers.create_test_event()
  let assert Ok(res) =
    delete_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
    )
    |> delete_event.build(helpers.creds())
    |> hackney.send
  let assert Ok(Nil) = delete_event.response(res)
  let assert Ok(res) =
    get_event.request(
      helpers.calendar_collection_path,
      helpers.test_event_filename,
    )
    |> get_event.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = get_event.response(res)
}

// CardDAV

pub fn carddav_discover_addressbook_home_test() {
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(helpers.creds())
    |> hackney.send
  let assert Ok(principal) = discover_principal.response(res)
  let assert Ok(res) =
    discover_addressbook_home.request(principal)
    |> discover_addressbook_home.build(helpers.creds())
    |> hackney.send
  let assert Ok(home) = discover_addressbook_home.response(res)
  home |> should.not_equal("")
}

pub fn carddav_list_addressbooks_test() {
  let assert Ok(res) =
    discover_principal.request()
    |> discover_principal.build(helpers.creds())
    |> hackney.send
  let assert Ok(principal) = discover_principal.response(res)
  let assert Ok(res) =
    discover_addressbook_home.request(principal)
    |> discover_addressbook_home.build(helpers.creds())
    |> hackney.send
  let assert Ok(home) = discover_addressbook_home.response(res)
  let assert Ok(res) =
    list_addressbooks.request(home)
    |> list_addressbooks.build(helpers.creds())
    |> hackney.send
  let assert Ok(addressbooks) = list_addressbooks.response(res)
  list.is_empty(addressbooks) |> should.be_false
}

pub fn carddav_get_addressbook_info_test() {
  let assert Ok(res) =
    get_addressbook_info.request(helpers.addressbook_collection_path)
    |> get_addressbook_info.build(helpers.creds())
    |> hackney.send
  let assert Ok(info) = get_addressbook_info.response(res)
  info.displayname |> should.not_equal("")
  info.ctag |> should.not_equal("")
}

pub fn carddav_create_contact_test() {
  helpers.cleanup_contact()
  let assert Ok(res) =
    create_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
      helpers.test_vcardstring,
    )
    |> create_contact.build(helpers.creds())
    |> hackney.send
  let assert Ok(_) = create_contact.response(res)
}

pub fn carddav_get_contact_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    get_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
    )
    |> get_contact.build(helpers.creds())
    |> hackney.send
  let assert Ok(vcard) = get_contact.response(res)
  string.contains(vcard, "gdav Test Contact") |> should.be_true
}

pub fn carddav_get_contact_not_found_test() {
  helpers.cleanup_contact()
  let assert Ok(res) =
    get_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
    )
    |> get_contact.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = get_contact.response(res)
}

pub fn carddav_get_all_contacts_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    get_all_contacts.request(helpers.addressbook_collection_path)
    |> get_all_contacts.build(helpers.creds())
    |> hackney.send
  let assert Ok(contacts) = get_all_contacts.response(res)
  list.is_empty(contacts) |> should.be_false
}

pub fn carddav_get_contact_etags_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    get_contact_etags.request(helpers.addressbook_collection_path)
    |> get_contact_etags.build(helpers.creds())
    |> hackney.send
  let assert Ok(pairs) = get_contact_etags.response(res)
  list.is_empty(pairs) |> should.be_false
}

pub fn carddav_update_contact_test() {
  helpers.cleanup_contact()
  let etag = helpers.create_test_contact()
  let assert Ok(res) =
    update_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
      etag,
      helpers.updated_vcardstring,
    )
    |> update_contact.build(helpers.creds())
    |> hackney.send
  let assert Ok(Nil) = update_contact.response(res)
  let assert Ok(res) =
    get_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
    )
    |> get_contact.build(helpers.creds())
    |> hackney.send
  let assert Ok(vcard) = get_contact.response(res)
  string.contains(vcard, "gdav Test Contact Updated") |> should.be_true
}

pub fn carddav_update_contact_stale_etag_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    update_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
      "wrong-etag",
      helpers.updated_vcardstring,
    )
    |> update_contact.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = update_contact.response(res)
}

pub fn carddav_multiget_contacts_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    multiget_contacts.request(helpers.addressbook_collection_path, [
      helpers.test_contact_path,
    ])
    |> multiget_contacts.build(helpers.creds())
    |> hackney.send
  let assert Ok(entries) = multiget_contacts.response(res)
  let assert [entry] = entries
  string.contains(entry.data, "gdav Test Contact") |> should.be_true
}

pub fn carddav_sync_collection_test() {
  helpers.cleanup_contact()
  let assert Ok(res) =
    get_addressbook_info.request(helpers.addressbook_collection_path)
    |> get_addressbook_info.build(helpers.creds())
    |> hackney.send
  let assert Ok(info) = get_addressbook_info.response(res)
  let token_before = case info.sync_token {
    Some(t) -> t
    None -> ""
  }

  let _etag = helpers.create_test_contact()

  let assert Ok(res) =
    sync_collection.request(helpers.addressbook_collection_path, token_before)
    |> sync_collection.build(helpers.creds())
    |> hackney.send
  let assert Ok(sync1) = sync_collection.response(res)
  list.is_empty(sync1.changed) |> should.be_false

  helpers.cleanup_contact()

  let assert Ok(res) =
    sync_collection.request(
      helpers.addressbook_collection_path,
      sync1.sync_token,
    )
    |> sync_collection.build(helpers.creds())
    |> hackney.send
  let assert Ok(sync2) = sync_collection.response(res)
  list.is_empty(sync2.deleted) |> should.be_false
}

pub fn carddav_delete_contact_test() {
  helpers.cleanup_contact()
  let _etag = helpers.create_test_contact()
  let assert Ok(res) =
    delete_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
    )
    |> delete_contact.build(helpers.creds())
    |> hackney.send
  let assert Ok(Nil) = delete_contact.response(res)
  let assert Ok(res) =
    get_contact.request(
      helpers.addressbook_collection_path,
      helpers.test_contact_filename,
    )
    |> get_contact.build(helpers.creds())
    |> hackney.send
  let assert Error(_) = get_contact.response(res)
}
