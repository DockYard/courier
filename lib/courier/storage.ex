defmodule Courier.Storage do
  @moduledoc """
  Contains behaviours for Storage based adapters

  `use` this module in your adapter:

      defmodule CustomAdapter do
        use Courier.Storage
      end
  """

  @callback messages() :: [Mail.Message.t()]
  @callback messages_for(String.t()) :: [Mail.Message.t()]
  @callback recipients() :: [String.t()]
  @callback clear() :: any
  @callback delete(Mail.Message.t()) :: :ok

  defmacro __using__([]) do
    quote do
      @behaviour Courier.Storage

      def messages_for(recipient) do
        Enum.filter(
          messages(),
          &Enum.member?(uniq_emails(&1), recipient)
        )
      end

      def recipients do
        Enum.reduce(messages(), [], &(uniq_emails(&1) ++ &2))
        |> Enum.uniq()
      end

      def uniq_emails(message) do
        Mail.all_recipients(message)
        |> Enum.map(fn
          {_, email} -> email
          email -> email
        end)
        |> Enum.uniq()
      end
    end
  end
end
