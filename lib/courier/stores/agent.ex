defmodule Courier.Stores.Agent do
  defmacro __using__(_) do
    quote do
      def start_link() do
        Agent.start_link(fn -> [] end, name: __MODULE__)
      end

      def pop(past: true) do
        Agent.get_and_update(__MODULE__, &before_now/1)
      end

      def pop() do
        Agent.get_and_update(__MODULE__, &({&1, []}))
      end

      def put({%Mail.Message{} = message, timestamp}),
        do: put({message, timestamp, []})

      def put({%Mail.Message{} = message, timestamp, opts}) do
        Agent.update(__MODULE__, fn(messages) -> [{message, timestamp, opts} | messages] end)
      end

      def clear(),
        do: Agent.update(__MODULE__, fn(_) -> [] end)

      defp before_now(messages) do
        current_seconds =
          :calendar.universal_time()
          |> :calendar.datetime_to_gregorian_seconds()

        messages
        |> Enum.reduce({[], []}, fn({message, timestamp, opts}, {acc, state}) ->
          cond do
            :calendar.datetime_to_gregorian_seconds(timestamp) <= current_seconds ->
              {[{message, timestamp, opts} | acc], state}
            true ->
              {acc, [{message, timestamp, opts} | state]}
          end
        end)
      end
    end
  end
end
