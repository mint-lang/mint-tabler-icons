require "xml"

class String
  def indent(spaces : Int32 = 2) : String
    lines.join('\n') do |line|
      line.empty? ? line : (" " * spaces) + line
    end
  end
end

icons = {} of String => String

def copy(node, xml)
  node.children.each do |child|
    next if child.text?
    next if child["stroke"]? == "none" && child["fill"]? == "none"

    xml.element(child.name) do
      child.attributes.each do |attribute|
        xml.attribute(attribute.name, attribute.content)
        copy(child, xml)
      end
    end
  end
end

Dir.glob("tabler-icons/icons/*") do |file|
  document = XML.parse(File.read(file))

  if svg = document.first_element_child
    string = XML.build(indent: "  ") do |xml|
      xml.element("svg") do
        xml.attribute("viewBox", svg["viewBox"])
        xml.element("g") do
          xml.attribute("style", "stroke-width: var(--tabler-stroke-width);")
          xml.attribute("stroke-linejoin", svg["stroke-linejoin"])
          xml.attribute("stroke-linecap", svg["stroke-linecap"])
          xml.attribute("stroke", "currentColor")
          xml.attribute("fill", svg["fill"])

          copy(svg, xml)
        end
      end
    end

    name =
      File.basename(file, ".svg").upcase.gsub("-", "_")

    html =
      string.sub("<?xml version=\"1.0\"?>\n", "").indent

    icons[name] = html
  end
end

content =
  icons
    .map { |name, html| "const #{name} =\n#{html}" }
    .join("\n\n")
    .indent

source =
  "module TablerIcons {\n#{content}\n}"

mainContent =
  icons
    .keys
    .map { |name| "<{ TablerIcons:#{name} }>" }
    .join("\n")
    .indent(8)

main =
  <<-MINT
  component Main {
    state strokeWidth : String = "1"

    style base {
      --tabler-stroke-width: \#{strokeWidth};

      svg {
        height: 30px;
        width: 30px;
      }
    }

    fun render : Html {
      <div::base>
        <input
          onInput={(event : Html.Event) { next { strokeWidth = Dom.getValue(event.target) } }}
          value={strokeWidth}
          step="0.25"
          type="range"
          min="1"
          max="5"/>

  #{mainContent}
      </div>
    }
  }
  MINT

File.write("source/Icons.mint", source)
File.write("source/Main.mint", main)
