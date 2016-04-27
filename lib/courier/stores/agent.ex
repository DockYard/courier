defmodule Courier.Stores.Agent do
  defmacro __using__(_) do
    quote do
      def start_link() do
        Agent.start_link(fn -> [] end, name: __MODULE__)
      end

      def all(past: true) do
        Agent.get(__MODULE__, &before_now/1)
      end

      def all() do
        Agent.get(__MODULE__, &strip_timestamps/1)
      end

      def put({%Mail.Message{} = message, timestamp}) do
        Agent.update(__MODULE__, fn(messages) -> [{message, timestamp} | messages] end)
      end

      def delete(%Mail.Message{} = message) do
        Agent.update(__MODULE__, fn(messages) -> 
          messages
          |> Enum.find_index(&(message == elem(&1, 0)))
          |> case do
            nil -> messages
            idx -> List.delete_at(messages, idx)
          end
        end)
      end

      def delete([]), do: :ok
      def delete([%Mail.Message{} = message |  messages]) when is_list(messages) do
        delete(message)
        delete(messages)
      end

      def clear(),
        do: Agent.update(__MODULE__, fn(_) -> [] end)

      defp before_now(messages) do
        current_seconds =
          :calendar.universal_time()
          |> :calendar.datetime_to_gregorian_seconds()

        messages
        |> Enum.reduce([], fn({message, timestamp}, acc) ->
          cond do
            :calendar.datetime_to_gregorian_seconds(timestamp) <= current_seconds -> [message | acc]
            true -> acc
          end
        end)
      end

      defp strip_timestamps(messages) do
        messages
        |> Enum.map(&(elem(&1, 0)))
      end
    end
  end
end
