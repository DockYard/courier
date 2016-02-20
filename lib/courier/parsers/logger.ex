defmodule Courier.Parsers.Logger do
  @doc """
  Will parse the Logger rendering.

  Delegates to `Mail.Parsers.RFC2822`
  """
  def parse(content) do
    Mail.Parsers.RFC2822.parse(content)
  end
end
