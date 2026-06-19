import gdav
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import xmlm

pub const ns_dav = "DAV:"

pub const ns_caldav = "urn:ietf:params:xml:ns:caldav"

pub const ns_carddav = "urn:ietf:params:xml:ns:carddav"

pub const ns_cs = "http://calendarserver.org/ns/"

pub type Property {
  TextProp(name: xmlm.Name, value: String)
  HrefProp(name: xmlm.Name, href: String)
}

pub type DavResponse {
  DavResponse(href: String, status_code: Int, properties: List(Property))
}

pub fn parse_multistatus(
  body: String,
) -> Result(List(DavResponse), gdav.DavError) {
  use #(responses, _) <- result.try(parse_sync_report(body))
  Ok(responses)
}

pub fn parse_propfind(body: String) -> Result(DavResponse, gdav.DavError) {
  use responses <- result.try(parse_multistatus(body))
  case responses {
    [r, ..] -> Ok(r)
    [] -> Error(gdav.XmlParseError("Empty multistatus response"))
  }
}

pub fn parse_sync_report(
  body: String,
) -> Result(#(List(DavResponse), String), gdav.DavError) {
  xmlm.from_string(body)
  |> do_parse_multistatus
  |> result.map_error(fn(e) {
    gdav.XmlParseError(xmlm.input_error_to_string(e))
  })
}

pub fn parse_single_value(
  body: String,
  container: xmlm.Name,
) -> Result(String, gdav.DavError) {
  use response <- result.try(parse_propfind(body))
  case
    list.find_map(response.properties, fn(p) {
      case p {
        HrefProp(name, href) if name == container -> Ok(href)
        _ -> Error(Nil)
      }
    })
  {
    Ok(href) -> Ok(href)
    Error(_) ->
      Error(gdav.XmlParseError("Property not found: " <> container.local))
  }
}

pub fn find_text(
  props: List(Property),
  ns: String,
  local: String,
) -> Result(String, Nil) {
  list.find_map(props, fn(p) {
    case p {
      TextProp(xmlm.Name(uri, loc), v) if uri == ns && loc == local -> Ok(v)
      _ -> Error(Nil)
    }
  })
}

fn do_parse_multistatus(
  input: xmlm.Input,
) -> Result(#(List(DavResponse), String), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.Dtd(_) | xmlm.Data(_) -> do_parse_multistatus(input)
    xmlm.ElementStart(_) -> collect_responses(input, [], "")
    xmlm.ElementEnd -> Ok(#([], ""))
  }
}

fn collect_responses(
  input: xmlm.Input,
  acc: List(DavResponse),
  sync_token: String,
) -> Result(#(List(DavResponse), String), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementStart(tag) -> {
      case tag.name {
        xmlm.Name(uri, "response") if uri == ns_dav -> {
          use #(response, input) <- result.try(parse_one_response(input))
          collect_responses(input, [response, ..acc], sync_token)
        }
        xmlm.Name(uri, "sync-token") if uri == ns_dav -> {
          use #(text, input) <- result.try(read_text(input))
          collect_responses(input, acc, text)
        }
        _ -> {
          use #(_, input) <- result.try(skip_element(input))
          collect_responses(input, acc, sync_token)
        }
      }
    }
    xmlm.ElementEnd -> Ok(#(list.reverse(acc), sync_token))
    xmlm.Data(_) | xmlm.Dtd(_) -> collect_responses(input, acc, sync_token)
  }
}

fn parse_one_response(
  input: xmlm.Input,
) -> Result(#(DavResponse, xmlm.Input), xmlm.InputError) {
  do_parse_one_response(input, "", 0, [])
}

fn do_parse_one_response(
  input: xmlm.Input,
  href: String,
  status_code: Int,
  props: List(Property),
) -> Result(#(DavResponse, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementStart(tag) -> {
      case tag.name {
        xmlm.Name(uri, "href") if uri == ns_dav -> {
          use #(text, input) <- result.try(read_text(input))
          do_parse_one_response(input, text, status_code, props)
        }
        xmlm.Name(uri, "propstat") if uri == ns_dav -> {
          use #(new_props, pstat_code, input) <- result.try(parse_propstat(
            input,
          ))
          let props = case pstat_code >= 200 && pstat_code < 300 {
            True -> list.append(props, new_props)
            False -> props
          }
          let status_code = case status_code == 0 {
            True -> pstat_code
            False -> status_code
          }
          do_parse_one_response(input, href, status_code, props)
        }
        xmlm.Name(uri, "status") if uri == ns_dav -> {
          use #(text, input) <- result.try(read_text(input))
          let code = parse_status_code(text)
          do_parse_one_response(input, href, code, props)
        }
        _ -> {
          use #(_, input) <- result.try(skip_element(input))
          do_parse_one_response(input, href, status_code, props)
        }
      }
    }
    xmlm.ElementEnd ->
      Ok(#(DavResponse(href:, status_code:, properties: props), input))
    xmlm.Data(_) | xmlm.Dtd(_) ->
      do_parse_one_response(input, href, status_code, props)
  }
}

fn parse_propstat(
  input: xmlm.Input,
) -> Result(#(List(Property), Int, xmlm.Input), xmlm.InputError) {
  do_parse_propstat(input, [], 0)
}

fn do_parse_propstat(
  input: xmlm.Input,
  props: List(Property),
  status_code: Int,
) -> Result(#(List(Property), Int, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementStart(tag) -> {
      case tag.name {
        xmlm.Name(uri, "prop") if uri == ns_dav -> {
          use #(new_props, input) <- result.try(parse_props(input, []))
          do_parse_propstat(input, list.append(props, new_props), status_code)
        }
        xmlm.Name(uri, "status") if uri == ns_dav -> {
          use #(text, input) <- result.try(read_text(input))
          do_parse_propstat(input, props, parse_status_code(text))
        }
        _ -> {
          use #(_, input) <- result.try(skip_element(input))
          do_parse_propstat(input, props, status_code)
        }
      }
    }
    xmlm.ElementEnd -> Ok(#(props, status_code, input))
    xmlm.Data(_) | xmlm.Dtd(_) -> do_parse_propstat(input, props, status_code)
  }
}

fn parse_props(
  input: xmlm.Input,
  acc: List(Property),
) -> Result(#(List(Property), xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementStart(tag) -> {
      use #(prop, input) <- result.try(parse_one_prop(input, tag.name))
      parse_props(input, [prop, ..acc])
    }
    xmlm.ElementEnd -> Ok(#(list.reverse(acc), input))
    xmlm.Data(_) | xmlm.Dtd(_) -> parse_props(input, acc)
  }
}

fn parse_one_prop(
  input: xmlm.Input,
  name: xmlm.Name,
) -> Result(#(Property, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.Data(text) -> {
      case string.trim(text) {
        "" -> parse_one_prop(input, name)
        _ -> {
          use #(_, input) <- result.try(skip_remaining_children(input))
          Ok(#(TextProp(name, text), input))
        }
      }
    }
    xmlm.ElementEnd -> Ok(#(TextProp(name, ""), input))
    xmlm.ElementStart(child_tag) -> {
      case child_tag.name {
        xmlm.Name(uri, "href") if uri == ns_dav -> {
          use #(href_text, input) <- result.try(read_text(input))
          use #(_, input) <- result.try(skip_remaining_children(input))
          Ok(#(HrefProp(name, href_text), input))
        }
        _ -> {
          use #(_, input) <- result.try(skip_element(input))
          parse_one_prop(input, name)
        }
      }
    }
    xmlm.Dtd(_) -> parse_one_prop(input, name)
  }
}

fn skip_remaining_children(
  input: xmlm.Input,
) -> Result(#(Nil, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementEnd -> Ok(#(Nil, input))
    xmlm.ElementStart(_) -> {
      use #(_, input) <- result.try(skip_element(input))
      skip_remaining_children(input)
    }
    xmlm.Data(_) | xmlm.Dtd(_) -> skip_remaining_children(input)
  }
}

fn skip_element(
  input: xmlm.Input,
) -> Result(#(Nil, xmlm.Input), xmlm.InputError) {
  do_skip_element(input, 0)
}

fn do_skip_element(
  input: xmlm.Input,
  depth: Int,
) -> Result(#(Nil, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.ElementStart(_) -> do_skip_element(input, depth + 1)
    xmlm.ElementEnd if depth == 0 -> Ok(#(Nil, input))
    xmlm.ElementEnd -> do_skip_element(input, depth - 1)
    _ -> do_skip_element(input, depth)
  }
}

fn read_text(
  input: xmlm.Input,
) -> Result(#(String, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.Data(text) -> {
      use #(_, input) <- result.try(skip_remaining_children(input))
      Ok(#(text, input))
    }
    xmlm.ElementEnd -> Ok(#("", input))
    xmlm.ElementStart(_) -> {
      use #(_, input) <- result.try(skip_element(input))
      read_text_tail(input)
    }
    xmlm.Dtd(_) -> read_text(input)
  }
}

fn read_text_tail(
  input: xmlm.Input,
) -> Result(#(String, xmlm.Input), xmlm.InputError) {
  use #(signal, input) <- result.try(xmlm.signal(input))
  case signal {
    xmlm.Data(text) -> {
      use #(_, input) <- result.try(skip_remaining_children(input))
      Ok(#(text, input))
    }
    xmlm.ElementEnd -> Ok(#("", input))
    xmlm.ElementStart(_) -> {
      use #(_, input) <- result.try(skip_element(input))
      read_text_tail(input)
    }
    xmlm.Dtd(_) -> read_text_tail(input)
  }
}

fn parse_status_code(status: String) -> Int {
  case string.split(status, " ") {
    [_, code, ..] -> int.parse(code) |> result.unwrap(0)
    _ -> 0
  }
}
