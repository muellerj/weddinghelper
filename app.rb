require "sinatra"
require_relative "lib/location_detail_processor"

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
