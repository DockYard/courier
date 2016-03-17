defmodule Courier.Adapters.SMTPBase do
  @moduledoc """
  SMTP Adapter

  All messages are sent non-blocking.
  """

  defmacro __using__([]) do
    quote do
      @behaviour Courier.Adapter

      @doc false
      def init(_), do: nil

      @doc """
      Primary delivery hook

      The `options` must be a Keyword list. The keys must be atoms. The options conform to the options
      expected in `[gen_smtp_client](https://github.com/Vagabond/gen_smtp#client-example)`
      """
      def deliver(message, opts)
      def deliver(%Mail.Message{} = message, opts) do
        rendered_message =
          message
          |> strip_bcc()
          |> Mail.Renderers.RFC2822.render()
        :gen_smtp_client.send({from(message), to(message), rendered_message}, opts)
      end

      defp from(message) do
        case message.headers.from do
          {name, email} -> email
          email -> email
        end
      end

      defp to(message) do
        Mail.all_recipients(message)
        |> Enum.map(fn
          {name, email} -> email
          email -> email
        end)
        |> Enum.uniq()
      end

      defp strip_bcc(message) do
        Mail.Message.delete_header(message, :bcc)
      end
    end
  end
end
