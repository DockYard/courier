defmodule Courier.Case do
  defmacro __using__([]) do
    quote do
      import Courier.Adapters.Test, only: [messages_for: 1, messages: 0, clear: 0]
      setup do
        Courier.Adapters.Test.clear()

        :ok
      end
    end
  end
end
