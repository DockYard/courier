defmodule Courier.Test do
  use ExUnit.Case

  defmodule DeliverySuccess do
    defexception message: "Delivered!"
  end

  defmodule TestAdapter do
    def init(_), do: nil
    def deliver(%Mail.Message{} = _message, _opts) do
      raise DeliverySuccess
    end
  end

  defmodule OptionTestAdapter do
    def init(_), do: nil
    def deliver(%Mail.Message{} = _message, opts) do
      if opts[:success] do
        raise DeliverySuccess
      end
    end
  end

  defmodule DateTestAdapter do
    def init(_), do: nil
    def deliver(%Mail.Message{} = message, _opts) do
      if Mail.Message.get_header(message, :date) do
        raise DeliverySuccess
      end
    end
  end

  defmodule View do
    use Phoenix.View, root: "test/fixtures/templates"
    use Phoenix.HTML

    def upcase(message),
      do: String.upcase(message)
  end

  Application.put_env(:test, Courier.Test.MyMailer, [adapter: TestAdapter])
  defmodule MyMailer, do: use Courier, otp_app: :test

  Application.put_env(:test, Courier.Test.MyOptionMailer, [adapter: OptionTestAdapter, success: false])
  defmodule MyOptionMailer, do: use Courier, otp_app: :test

  Application.put_env(:test, Courier.Test.MyDateMailer, [adapter: DateTestAdapter])
  defmodule MyDateMailer, do: use Courier, otp_app: :test

  test "Using Courier: parsing config" do
    assert MyMailer.__adapter__ == TestAdapter
  end

  test "Using Courier: parsing config" do
    assert MyMailer.__adapter__ == TestAdapter
  end

  test "delivering a message delegates to the adapter" do
    assert_raise DeliverySuccess, fn ->
      MyMailer.deliver(Mail.build())
    end
  end

  test "delivering a message with options will override the inherited options from config" do
    assert_raise DeliverySuccess, fn ->
      MyOptionMailer.deliver(Mail.build(), success: true)
    end
  end

  test "delivering a message will inject a date into the message header" do
    assert_raise DeliverySuccess, fn ->
      MyDateMailer.deliver(Mail.build())
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
