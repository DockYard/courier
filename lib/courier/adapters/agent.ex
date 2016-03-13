defmodule Courier.Adapters.Agent do
  @moduledoc """
  Agent Adapter

  This adapter is not intended to be used directly but instead should be
  used by another adapter:

      defmodule MyCustomAdapter do
        use Courier.Adapters.Agent
      end
  """

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:deliver, 2}, (quote do: [message, config]), """
  Delivers the message by storing in an Agent
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:messages, 0}, (quote do: []), """
  Returns a list of all messages in the Agent

  Returns an empty list if no messages are found
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:messages_for, 1}, (quote do: [recipient]), """
  Returns a list of all messages for the given recipient

      defmodule MockAdapter do
        use Courier.Adapters.Agent
      end
      MockAdapter.init([])
      MockAdapter.messages_for("joe@example.com")
      [%Mail.Message{...}, %Mail.Message{...}]
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:recipients, 0}, (quote do: []), """
  Unique list of all recipients for all messages

  Will include `BCC` recipients

      defmodule MockAdapter do
        use Courier.Adapters.Agent
      end
      MockAdapter.init([])
      MockAdapter.all_recipients()
      ["joe@example.com", {"Brian", "brian@example.com"}]
  """)

  Module.add_doc(__MODULE__, __ENV__.line + 1, :def, {:clear, 0}, (quote do: []), """
  Clears all messages
  """)
  defmacro __using__([]) do
    quote do
      @behaviour Courier.Adapter
      @behaviour Courier.Storage

      def init(_) do
        Agent.start_link(fn -> [] end, name: __MODULE__)
      end

      def deliver(%Mail.Message{} = message, _config) do
        Agent.update(__MODULE__, fn(messages) -> [message | messages] end)
      end

      def messages() do
        Agent.get(__MODULE__, fn(messages) -> messages end)
      end

      def messages_for(recipient) do
        Enum.filter messages(),
          &(Enum.member?(Mail.all_recipients(&1), recipient))
      end

      def recipients do
        Enum.reduce(messages(), [], &(Mail.all_recipients(&1) ++ &2))
        |> Enum.uniq()
      end

      def clear(),
        do: Agent.update(__MODULE__, fn(_) -> [] end)
    end
  end
end
