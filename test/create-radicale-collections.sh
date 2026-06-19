#!/usr/bin/env bash
set -euo pipefail

curl -sf -u admin:admin -X MKCALENDAR \
	-H "Content-Type: application/xml; charset=utf-8" \
	-d '<?xml version="1.0" encoding="UTF-8"?><C:mkcalendar xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav"><D:set><D:prop><D:displayname>Test Calendar</D:displayname><C:supported-calendar-component-set><C:comp name="VEVENT"/></C:supported-calendar-component-set></D:prop></D:set></C:mkcalendar>' \
	http://localhost:5232/admin/calendar/

curl -sf -u admin:admin -X MKCOL \
	-H "Content-Type: application/xml; charset=utf-8" \
	-d '<?xml version="1.0" encoding="UTF-8"?><D:mkcol xmlns:D="DAV:" xmlns:CR="urn:ietf:params:xml:ns:carddav"><D:set><D:prop><D:resourcetype><D:collection/><CR:addressbook/></D:resourcetype><D:displayname>Test Contacts</D:displayname></D:prop></D:set></D:mkcol>' \
	http://localhost:5232/admin/contacts/
