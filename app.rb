require "sinatra"
require_relative "lib/location_detail_processor"

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
  render_form(LocationDetailProcessor.template)
end

post "/" do
  render_form(LocationDetailProcessor.call(params[:content]))
end
