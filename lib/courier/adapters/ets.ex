defmodule Courier.Adapters.ETS do
  @moduledoc """
  ETS Adapter

  This adapter is not intended to be used directly but instead should be
  used by another adapter:

      defmodule MyCustomAdapter do
        use Courier.Adapters.ETS, table: :custom_table
      end
  """

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:deliver, 2}, (quote do: [message, config]), """
  Delivers the message by storing on ETS
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:messages, 0}, (quote do: []), """
  Returns a list of all messages in ETS

  Returns an empty list if no messages are found
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:messages_for, 1}, (quote do: [recipient]), """
  Returns a list of all messages for the given recipient

      defmodule MockAdapter do
        use Courier.Adapters.ETS, table: :mock
      end
      MockAdapter.init([])
      MockAdapter.messages_for("joe@example.com")
      [%Mail.Message{...}, %Mail.Message{...}]
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:recipients, 0}, (quote do: []), """
  Unique list of all recipients for all messages

  Will include `BCC` recipients

      defmodule MockAdapter do
        use Courier.Adapters.ETS, table: :mock
      end
      MockAdapter.init([])
      MockAdapter.all_recipients()
      ["joe@example.com", {"Brian", "brian@example.com"}]
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:clear, 0}, (quote do: []), """
  Clears all messages
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:delete, 1}, (quote do: [message]), """
  Deletes the specific message

  Returns the list of remaning messages.
  """ )

  defmacro __using__([]),
    do: raise """
    No table name was given. Must be used in the form:

        use Courier.Adapters.ETS, table: :custom_name
    """
  defmacro __using__([table: table_name]) do
    quote do
      use Courier.Storage
      @behaviour Courier.Adapter

      def init(_) do
        :ets.new(unquote(table_name), [:named_table, :public])
      end

      def deliver(%Mail.Message{} = message, _config) do
        case :ets.lookup(unquote(table_name), :messages) do
          [] -> :ets.insert(unquote(table_name), {:messages, [message]})
          [{:messages, messages}] when is_list(messages) ->
            :ets.insert(unquote(table_name), {:messages, [message|messages]})
        end
      end

      def messages do
        case :ets.lookup(unquote(table_name), :messages) do
          [] -> []
          [{:messages, messages}] -> messages
        end
      end

      def clear(),
        do: :ets.delete(unquote(table_name), :messages)

      def delete(message) do
        :ets.insert(unquote(table_name), {:messages, List.delete(messages(), message)})
      end
    end
  end
end
