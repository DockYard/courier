defmodule Courier.Test do
  use ExUnit.Case

  import Mock

  defmodule TestAdapter do
    def init(_), do: nil
    def deliver(%Mail.Message{} = _message, %{} = _config), do: nil
  end

  defmodule View do
    use Phoenix.View, root: "test/fixtures/templates"
    use Phoenix.HTML

    def upcase(message),
      do: String.upcase(message)
  end

  Application.put_env(:test, Courier.Test.MyMailer, %{
    adapter: TestAdapter
  })

  defmodule MyMailer do
    use Courier, otp_app: :test
  end

  test "Using Courier: parsing config" do
    assert MyMailer.__adapter__ == TestAdapter
  end

  test "delivering a message delegates to the adapter" do
    with_mock Courier.Test.TestAdapter, [deliver: fn(_message, _config) -> "delivered" end] do
      Courier.Test.MyMailer.deliver(%Mail.Message{})

      assert called Courier.Test.TestAdapter.deliver(%Mail.Message{}, %{adapter: Courier.Test.TestAdapter})
    end
  end

  test "rendering text from a view into a message" do
    mail =
      Mail.build_multipart()
      |> Courier.render(View, "test.txt", %{foo: "foo", bar: "Test"})

    text_part = Mail.get_text(mail)
    assert text_part.body == "FOO Test\n"
  end

  test "rendering html from a view into a message" do
    mail =
      Mail.build_multipart()
      |> Courier.render(View, "test.html", %{foo: "foo", bar: "Test"})

    html_part = Mail.get_html(mail)
    assert html_part.body == "<span>FOO Test</span>\n"
  end
end
