import gdav
import gleam/list
import gleam/string

pub type ElementParser {
  ElementParser(data: String, tag: String)
}

pub fn element(data: String, tag: String) -> ElementParser {
  ElementParser(data:, tag:)
}

fn local_name(tag: String) -> String {
  case string.split_once(tag, ":") {
    Ok(#(_, local)) -> local
    Error(_) -> tag
  }
}

fn unescape(s: String) -> String {
  s
  |> string.replace("&quot;", "\"")
  |> string.replace("&apos;", "'")
  |> string.replace("&lt;", "<")
  |> string.replace("&gt;", ">")
  |> string.replace("&amp;", "&")
}

fn strip_closing_prefix(s: String) -> String {
  let parts = string.split(s, "</")
  case list.reverse(parts) {
    [] -> string.trim(s)
    [_] -> string.trim(s)
    [_, ..rest] -> rest |> list.reverse |> string.join("</") |> string.trim
  }
}

pub fn parse_element(
  parser: ElementParser,
) -> Result(List(String), gdav.DavError) {
  let local = local_name(parser.tag)
  case do_extract_all(parser.data, local, []) {
    [] -> Error(gdav.XmlParseError("No " <> parser.tag <> " elements found"))
    texts -> Ok(texts)
  }
}

fn do_extract_all(
  data: String,
  local: String,
  acc: List(String),
) -> List(String) {
  case string.split_once(data, local <> ">") {
    Error(_) -> list.reverse(acc)
    Ok(#(_, after_open)) ->
      case string.split_once(after_open, local <> ">") {
        Error(_) -> list.reverse(acc)
        Ok(#(raw, remaining)) -> {
          let content = raw |> strip_closing_prefix |> unescape
          do_extract_all(remaining, local, [content, ..acc])
        }
      }
  }
}

pub fn parse_first(data: String, tag: String) -> Result(String, gdav.DavError) {
  let local = local_name(tag)
  case string.split_once(data, local <> ">") {
    Error(_) -> Error(gdav.XmlParseError("No " <> tag <> " element found"))
    Ok(#(_, after_open)) ->
      case string.split_once(after_open, "<") {
        Error(_) -> Error(gdav.XmlParseError("Malformed " <> tag <> " element"))
        Ok(#(text, _)) ->
          case text |> string.trim |> unescape {
            "" -> Error(gdav.XmlParseError("Empty " <> tag <> " element"))
            unescaped -> Ok(unescaped)
          }
      }
  }
}

pub fn split_responses(data: String) -> List(String) {
  do_split_responses(data, [])
}

fn do_split_responses(data: String, acc: List(String)) -> List(String) {
  case string.split_once(data, "response>") {
    Error(_) -> list.reverse(acc)
    Ok(#(_, after_open)) ->
      case string.split_once(after_open, "response>") {
        Error(_) -> list.reverse(acc)
        Ok(#(raw_block, remaining)) -> {
          let block = strip_closing_prefix(raw_block)
          do_split_responses(remaining, [block, ..acc])
        }
      }
  }
}

pub fn parse_nested_href(
  data: String,
  container_tag: String,
) -> Result(String, gdav.DavError) {
  let local = local_name(container_tag)
  case string.split_once(data, local <> ">") {
    Error(_) ->
      Error(gdav.XmlParseError("No " <> container_tag <> " element found"))
    Ok(#(_, after_open)) ->
      case string.split_once(after_open, local <> ">") {
        Error(_) ->
          Error(gdav.XmlParseError("Unclosed " <> container_tag <> " element"))
        Ok(#(raw_inner, _)) -> {
          let inner = strip_closing_prefix(raw_inner)
          parse_first(inner, "d:href")
        }
      }
  }
}

pub fn parse_etag_list(
  data: String,
) -> Result(List(#(String, String)), gdav.DavError) {
  let pairs =
    split_responses(data)
    |> list.filter_map(fn(block) {
      case parse_first(block, "d:href"), parse_first(block, "d:getetag") {
        Ok(href), Ok(etag) -> Ok(#(href, etag))
        _, _ -> Error(Nil)
      }
    })
  Ok(pairs)
}
