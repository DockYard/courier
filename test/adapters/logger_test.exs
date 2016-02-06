defmodule McFeely.Test.LoggerTest do
  use ExUnit.Case
  require Logger
  import ExUnit.CaptureIO

  test "will output the message via the Logger defaulting to :info level" do
    message = %McFeely.Message{
      subject: "Let's go up the hill!",
      to: "jack@example.com",
      from: "jill@example.com",
      body: "To fetch a pail of water!"
    }

    output = capture_log(:info, fn ->
      McFeely.Adapters.Logger.deliver(message, %{})
    end)

    assert output =~ "Subject: Let's go up the hill!"
    assert output =~ "To: jack@example.com"
    assert output =~ "From: jill@example.com"
    assert output =~ "To fetch a pail of water!"
    assert output =~ "[info]"
  end

  test "will output the message to level :debug when specified in config" do
    message = %McFeely.Message{
      subject: "Let's go up the hill!",
      to: "jack@example.com",
      from: "jill@example.com",
      body: "To fetch a pail of water!"
    }

    output = capture_log(:debug, fn ->
      McFeely.Adapters.Logger.deliver(message, %{level: :debug})
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
