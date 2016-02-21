defmodule Courier.Adapters.SMTP do
  @moduledoc """
  SMTP Adapter

  All messages are sent non-blocking.
  """

  @doc """
  Primary delivery hook

  The `options` must be a Keyword list. The keys must be atoms. The options conform to the options
  expected in `[gen_smtp_client](https://github.com/Vagabond/gen_smtp#client-example)`
  """
  def deliver(message, config)
  def deliver(%Mail.Message{} = message, config) do
    rendered_message = Mail.Renderers.RFC2822.render(message)
    :gen_smtp_client.send({from(message), to(message), rendered_message}, options(config))
  end

  defp from(message) do
    message.headers.from
  end

  defp to(message) do
    Mail.all_recipients(message)
    |> Enum.map(fn
      {name, email} -> email
      email -> email
    end)
    |> Enum.uniq()
  end

  defp options(config),
    do: config
end
