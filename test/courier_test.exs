defmodule Courier.Test do
  use ExUnit.Case

  defmodule DeliverySuccess do
    defexception message: "Delivered!"
  end

  defmodule TestAdapter do
    def start_link(_), do: :ignore

    def deliver(%Mail.Message{} = _message, opts) do
      send(opts[:pid], :sent)

      :ok
    end
  end

  defmodule OptionTestAdapter do
    def start_link(_), do: :ignore

    def deliver(%Mail.Message{} = _message, opts) do
      if opts[:success] do
        send(opts[:pid], :sent)
      end

      :ok
    end
  end

  defmodule DateTestAdapter do
    def start_link(_), do: :ignore

    def deliver(%Mail.Message{} = message, opts) do
      if Mail.Message.get_header(message, :date) do
        send(opts[:pid], :sent)
      end

      :ok
    end
  end

  defmodule View do
    use Phoenix.View, root: "test/fixtures/templates"
    use Phoenix.HTML

    def upcase(message),
      do: String.upcase(message)
  end

  Application.put_env(:test, Courier.Test.MyMailer, adapter: TestAdapter)
  defmodule MyMailer, do: use(Courier, otp_app: :test)

  Application.put_env(:test, Courier.Test.MyOptionMailer,
    adapter: OptionTestAdapter,
    success: false
  )

  defmodule MyOptionMailer, do: use(Courier, otp_app: :test)

  Application.put_env(:test, Courier.Test.MyDateMailer, adapter: DateTestAdapter)
  defmodule MyDateMailer, do: use(Courier, otp_app: :test)

  test "Using Courier: parsing config" do
    assert MyMailer.__adapter__() == TestAdapter
  end

  test "delivering a message delegates to the adapter" do
    opts = [adapter: TestAdapter, interval: 1, pid: self()]

    {:ok, pid} =
      Courier.Scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    MyMailer.deliver(Mail.build(), opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "delivering a message with options will override the inherited options from config" do
    opts = [adapter: OptionTestAdapter, interval: 1, pid: self(), success: true]

    {:ok, pid} =
      Courier.Scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    MyOptionMailer.deliver(Mail.build(), opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "delivering a message will inject a date into the message header" do
    opts = [adapter: DateTestAdapter, interval: 1, pid: self()]

    {:ok, pid} =
      Courier.Scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    MyDateMailer.deliver(Mail.build(), opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
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
