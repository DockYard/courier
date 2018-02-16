defmodule Courier.Adapters.Agent do
  @moduledoc """
  Agent Adapter

  This adapter is not intended to be used directly but instead should be
  used by another adapter:

      defmodule MyCustomAdapter do
        use Courier.Adapters.Agent
      end
  """

  defmacro __using__([]) do
    quote do
      use Courier.Storage
      @behaviour Courier.Adapter

      def start_link(_opts) do
        Agent.start_link(fn -> [] end, name: __MODULE__)
      end

      @doc """
      Delivers the message by storing in an Agent
      """
      def deliver(%Mail.Message{} = message, _opts) do
        Agent.update(__MODULE__, fn(messages) -> [message | messages] end)
      end

      @doc """
      Returns a list of all messages in the Agent

      Returns an empty list if no messages are found
      """
      def messages() do
        Agent.get(__MODULE__, fn(messages) -> messages end)
      end

      @doc """
      Clears all messages
      """
      def clear(),
        do: Agent.update(__MODULE__, fn(_) -> [] end)

      @doc """
      Deletes the specific message

      Returns the list of remaning messages.
      """
      def delete(message) do
        Agent.update(__MODULE__, fn(messages) -> List.delete(messages, message) end)
      end

      defoverridable [deliver: 2, messages: 0, clear: 0, delete: 1]
    end
  end
end
