defmodule Courier.Renderers.Logger do
  import Mail.Renderers.RFC2822, only: [render_headers: 1]

  def render(%Mail.Message{multipart: true} = message) do
    headers = put_in(message.headers, [:mime_version], "1.0")

    Map.put(message, :headers, headers)
    |> render_part()
  end

  def render(%Mail.Message{} = message) do
    render_part(message)
  end

  def render_part(%Mail.Message{multipart: true} = message) do
    Mail.Renderers.RFC2822.render_part(message, &render_part/1)
  end

  def render_part(%Mail.Message{} = message) do
    "#{render_headers(message.headers)}\r\n\r\n#{render_body(message)}"
  end

  defp render_body(%Mail.Message{} = message) do
    content_disposition = message.headers[:content_disposition]

    cond do
      :attachment in List.wrap(content_disposition) -> "[File content]"
      true -> message.body
    end
  end
end
