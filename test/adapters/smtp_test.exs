defmodule Courier.Adapters.SMTPTest do
  use ExUnit.Case

  setup_all do
    {:ok, pid} = :gen_smtp_server.start(:smtp_server_example)

    on_exit fn ->
      Process.exit(pid, :kill)
    end

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

    {:ok, pid} = Courier.Adapters.SMTP.deliver(message, [relay: "localhost", port: 2525])

    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500
  end
end
