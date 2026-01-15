import gdav
import gleam/list
import presentable_soup as soup

pub type ElementParser {
  ElementParser(data: String, tag: String)
}

pub fn element(data: String, tag: String) {
  ElementParser(data:, tag:)
}

fn get_text(element: soup.Element) -> Result(String, gdav.DAVError) {
  case element {
    soup.Element(children: [soup.Text(text), ..], ..) -> Ok(text)
    soup.Element(children: [], ..) ->
      Error(gdav.XmlParseError("Element has no text content"))
    _ -> Error(gdav.XmlParseError("Expected text element"))
  }
}

pub fn parse_element(
  parser: ElementParser,
) -> Result(List(String), gdav.DAVError) {
  let query = soup.element([soup.tag(parser.tag)])

  case soup.find_all(in: parser.data, matching: query) {
    Ok(elements) -> {
      let texts = list.filter_map(elements, get_text)
      case texts {
        [] ->
          Error(gdav.XmlParseError(
            "No calendar data elements found with text content",
          ))
        _ -> Ok(texts)
      }
    }
    Error(_) ->
      Error(gdav.XmlParseError(
        "Failed to parse XML or find calendar data elements",
      ))
  }
}
