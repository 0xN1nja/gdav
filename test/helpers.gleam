import gdav
import gdav/create_contact
import gdav/create_event
import gdav/delete_contact
import gdav/delete_event
import gdav/get_contact_etags
import gdav/get_etags
import gleam/hackney
import gleam/list

pub const calendar_collection_path = "/admin/89b1a477-c5fa-c1ad-d2fc-6d59ce80f936"

pub const addressbook_collection_path = "/admin/contacts"

pub const test_event_filename = "gdav-test-event.ics"

pub const test_contact_filename = "gdav-test-contact.vcf"

pub const test_event_path = "/admin/89b1a477-c5fa-c1ad-d2fc-6d59ce80f936/gdav-test-event.ics"

pub const test_contact_path = "/admin/contacts/gdav-test-contact.vcf"

pub const test_icalstring = "BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//gdav test//EN
BEGIN:VEVENT
UID:gdav-test-uid@test
DTSTAMP:20250101T000000Z
DTSTART:20250201T100000Z
DTEND:20250201T110000Z
SUMMARY:gdav Test Event
END:VEVENT
END:VCALENDAR"

pub const updated_icalstring = "BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//gdav test//EN
BEGIN:VEVENT
UID:gdav-test-uid@test
DTSTAMP:20250101T000000Z
DTSTART:20250201T100000Z
DTEND:20250201T120000Z
SUMMARY:gdav Test Event Updated
END:VEVENT
END:VCALENDAR"

pub const test_vcardstring = "BEGIN:VCARD
VERSION:3.0
UID:gdav-test-contact-uid
FN:gdav Test Contact
N:Contact;gdav Test;;;
TEL;TYPE=cell:0000000000
END:VCARD"

pub const updated_vcardstring = "BEGIN:VCARD
VERSION:3.0
UID:gdav-test-contact-uid
FN:gdav Test Contact Updated
N:Contact Updated;gdav Test;;;
TEL;TYPE=cell:1111111111
END:VCARD"

pub fn creds() -> gdav.Credentials {
  gdav.credentials("http://localhost:5232/")
  |> gdav.with_basic_auth("admin", "admin")
}

pub fn cleanup_event() -> Nil {
  let _ =
    delete_event.request(calendar_collection_path, test_event_filename)
    |> delete_event.build(creds())
    |> hackney.send
  Nil
}

pub fn cleanup_contact() -> Nil {
  let _ =
    delete_contact.request(addressbook_collection_path, test_contact_filename)
    |> delete_contact.build(creds())
    |> hackney.send
  Nil
}

pub fn create_test_event() -> String {
  let assert Ok(res) =
    create_event.request(
      calendar_collection_path,
      test_event_filename,
      test_icalstring,
    )
    |> create_event.build(creds())
    |> hackney.send
  let assert Ok(_) = create_event.response(res)
  let assert Ok(res) =
    get_etags.request(calendar_collection_path)
    |> get_etags.build(creds())
    |> hackney.send
  let assert Ok(pairs) = get_etags.response(res)
  let assert Ok(#(_, etag)) =
    list.find(pairs, fn(pair) { pair.0 == test_event_path })
  etag
}

pub fn create_test_contact() -> String {
  let assert Ok(res) =
    create_contact.request(
      addressbook_collection_path,
      test_contact_filename,
      test_vcardstring,
    )
    |> create_contact.build(creds())
    |> hackney.send
  let assert Ok(_) = create_contact.response(res)
  let assert Ok(res) =
    get_contact_etags.request(addressbook_collection_path)
    |> get_contact_etags.build(creds())
    |> hackney.send
  let assert Ok(pairs) = get_contact_etags.response(res)
  let assert Ok(#(_, etag)) =
    list.find(pairs, fn(pair) { pair.0 == test_contact_path })
  etag
}
