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

RENAME = {
  "123"                => "ONE_TWO_THREE",
  "12_HOURS"           => "TWELVE_HOURS",
  "24_HOURS"           => "TWENTY_FOUR_HOURS",
  "2FA"                => "TWO_FA",
  "360_VIEW"           => "THREE_SIXTY_VIEW",
  "360"                => "THREE_SIXTY",
  "3D_CUBE_SPHERE_OFF" => "THREE_CUBE_SPHERE_OFF",
  "3D_CUBE_SPHERE"     => "THREE_CUBE_SPHERE",
  "3D_ROTATE"          => "THREE_ROTATE",
}

Dir.glob("tabler-icons/icons/**/*").to_a.sort.each do |file|
  base_name =
    File.basename(file, ".svg").upcase.gsub("-", "_")

  name =
    if file.includes?("filled")
      "#{base_name}_FILLED"
    else
      base_name
    end

  if name[0].ascii_number?
    name = RENAME[name]
  end

  next if File.directory?(file)

  document = XML.parse(File.read(file))

  if svg = document.first_element_child
    string = XML.build(indent: "  ") do |xml|
      xml.element("svg") do
        xml.attribute("viewBox", svg["viewBox"])
        xml.element("g") do
          if file.includes?("outline")
            xml.attribute("style", "stroke-width: var(--tabler-stroke-width);")
            xml.attribute("stroke-linejoin", svg["stroke-linejoin"])
            xml.attribute("stroke-linecap", svg["stroke-linecap"])
            xml.attribute("stroke", "currentColor")
          end

          xml.attribute("fill", svg["fill"])

          copy(svg, xml)
        end
      end
    end

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
          onInput={(event : Html.Event) { next { strokeWidth: Dom.getValue(event.target) } }}
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
