defmodule Courier.Adapters.LoggerTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureIO

  @adapter Courier.Adapters.Logger

  setup do
    {:ok, pid} =
      [Supervisor.Spec.supervisor(@adapter, [[]])]
      |> Supervisor.start_link(strategy: :one_for_one)

    {:ok, pid: pid}
  end

  test "will output the message via the Logger defaulting to :info level" do
    message =
      Mail.build()
      |> Mail.put_subject("Let's go up the hill!")
      |> Mail.put_to("jack@example.com")
      |> Mail.put_from("jill@example.com")
      |> Mail.put_text("To fetch a pail of water!")

    output =
      capture_log(:info, fn ->
        @adapter.deliver(message, [])
      end)

    assert output =~ "Subject: Let's go up the hill!"
    assert output =~ "To: jack@example.com"
    assert output =~ "From: jill@example.com"
    assert output =~ "To fetch a pail of water!"
    assert output =~ "[info]"
  end

  test "will output the message to level :debug when specified in config" do
    message =
      Mail.build()
      |> Mail.put_subject("Let's go up the hill!")
      |> Mail.put_to("jack@example.com")
      |> Mail.put_from("jill@example.com")
      |> Mail.put_text("To fetch a pail of water!")

    output =
      capture_log(:debug, fn ->
        @adapter.deliver(message, %{level: :debug})
      end)

    assert output =~ "Subject: Let's go up the hill!"
    assert output =~ "[debug]"
  end

  def capture_log(level \\ :debug, fun) do
    Logger.configure(level: level)

    capture_io(:user, fn ->
      fun.()
      Logger.flush()
    end)
  after
    Logger.configure(level: :debug)
  end
end
