defmodule Courier.Adapter do
  @callback deliver(Mail.Message.t(), Keyword.t()) :: any
end
