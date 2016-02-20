defmodule Courier.Renderers.LoggerTest do
  use ExUnit.Case

  test "rendering a singlepart message" do
    message =
      Mail.build()
      |> Mail.put_subject("Test")
      |> Mail.put_text("This is a test")

    result =
      Courier.Renderers.Logger.render(message)
      |> Courier.Parsers.Logger.parse()

    refute result.multipart
    assert result.headers.subject == "Test"
    assert result.body == "This is a test"
  end

  test "rendering a multipart message" do
    message =
      Mail.build_multipart()
      |> Mail.put_subject("Test")
      |> Mail.put_text("Some text")
      |> Mail.put_html("<h1>Some HTML</h1>")

    result =
      Courier.Renderers.Logger.render(message)
      |> Courier.Parsers.Logger.parse()

    assert result.multipart
    assert result.headers.subject == "Test"

    [text_part, html_part] = result.parts

    assert text_part.body == "Some text"
    assert html_part.body == "<h1>Some HTML</h1>"
  end

  test "replaces encoded file content with readable stub" do
    message =
      Mail.build()
      |> Mail.put_attachment("README.md")

    result = Courier.Renderers.Logger.render(message)

    encoded_file =
      File.read!("README.md")
      |> Mail.Encoder.encode(:base64)

    assert result =~ "[File content]"
    refute result =~ encoded_file
  end
end
