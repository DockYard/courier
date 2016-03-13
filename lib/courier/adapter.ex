defmodule Courier.Adapter do
  @callback init(List.t) :: any
  @callback deliver(Mail.Message.t, Keyword.t) :: any
end
