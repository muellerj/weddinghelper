require "sinatra"

def location_detail_template
  template = <<-EOT.gsub(/^ {4}/, '')
    # Template location

    \`\`\`address
    \`\`\`

    ---
    \`\`\`ruby
    \`\`\`
    ---

    Posten | Wert
    --- | ---:
    **TOTAL** | **4200**

    ---

    [Zurueck zur Liste der Locations](../locationlist.markdown)
  EOT
  template
end

class LocationDetailProcessor
  def self.process_location_detail(content)
    fileparts = content.gsub("\r", "").split(/^---$/)

    fail "Required file section not found!" if fileparts[1].nil?

    eval fileparts[1].lines.to_a[2..-2].join

    total = instance_variables.reduce(0) { |sum, v| sum += instance_variable_get(v) }

    outputtable = "\n\nPosten | Wert\n"
    outputtable << " --- | ---:\n"
    instance_variables.each do |var|
      outputtable << "#{var.to_s.tr("@", "").capitalize} | #{instance_variable_get(var).to_s}\n"
    end
    outputtable << "**TOTAL** | **#{total}**\n\n"

    newfile = fileparts
    newfile[2] = outputtable

    newfile.join("---")
  end
end

def render_form(content)
  erb <<-EOS
    <style>
      textarea {
        border:1px solid #999999;
        font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace;
        width: 600px;
        height: 400px;
        display: block;
      }
    </style>
    <form action="/" method="post">
      <textarea name="content">#{content}</textarea>
      <input type="submit" value="Process file" />
    </form>
  EOS
end

get "/" do
  render_form(location_detail_template)
end

post "/" do
  render_form(LocationDetailProcessor.process_location_detail(params[:content]))
end
