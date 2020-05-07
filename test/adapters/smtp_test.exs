defmodule Courier.Adapters.SMTPTest do
  use ExUnit.Case

  defmodule Server do
    def init(_hostname, _session_count, _address, options),
      do: {:ok, "", %{options: options}}

    def handle_EHLO(_hostname, extensions, state),
      do: {:ok, extensions, state}

    def handle_DATA(from, to, data, state) do
      send(get_in(state, [:options, :pid]), {from, to, data})

      {:ok, "foobar", state}
    end

    def handle_MAIL(_from, state),
      do: {:ok, state}

    def handle_RCPT(_to, state),
      do: {:ok, state}

    def terminate(reason, state),
      do: {:ok, reason, state}
  end

  setup do
    {:ok, _pid} =
      :gen_smtp_server.start_link(Server, [[sessionoptions: [callbackoptions: [pid: self()]]]])

    :ok
  end

  test "will properly send a message" do
    message =
      Mail.build()
      |> Mail.put_to("to@example.com")
      |> Mail.put_bcc("other@example.com")
      |> Mail.put_from("from@example.com")
      |> Mail.put_subject("Sending you a test")
      |> Mail.put_text("Hopefully it works!")

    Courier.Adapters.SMTP.deliver(message, relay: "localhost", port: 2525)

    receive do
      {from, to, data} ->
        assert from == "from@example.com"
        assert to == ["to@example.com", "other@example.com"]
        assert data =~ "Sending you a test"
        assert data =~ "Hopefully it works!"
        refute data =~ "other@example.com"
    after
      1000 ->
        raise "Expected message"
    end
  end
end
