defmodule Courier.Adapters.Test do
  use Courier.Adapters.Agent

  @moduledoc """
  This adapter should be used in your test environments. It requires no
  configuration.

      config :my_app, MyApp.Mailer,
        adapter: Courier.Adapters.Test,
        interval: 0,                     # Will force the poller to send instantly
        delivery_timeout: 1_000_000      # Useful if you want to use IEx.pry

  It is most suitable to use during acceptance tests. Because all messages
  are sent asynchronously via `Courier.Scheduler` you must block on their delivery.
  We can do this using `assert_receive/2`

      post(conn, "/sign-up", data)
      assert_receive {:delivered, message}, 100

  It is suggested to pass a small timeout value.

  All message delivery will be delegated to `Courier.Adapters.Agent` for storage.
  If you need to access to the messages you can do so at any time

      Courier.Adapters.Test.messages()

  In fact, any of the functions available in `Courier.Adapters.Agent` are available.
  """

  @doc false
  def deliver(%Mail.Message{} = message, opts) do
    case Keyword.fetch(opts, :sent_from) do
      {:ok, pid} -> send pid, {:delivered, message}
      :error -> nil
    end

    super(message, opts)
  end
end
