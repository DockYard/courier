defmodule Courier.Storage do
  @callback messages() :: [Mail.Message.t]
  @callback messages_for(String.t) :: [Mail.Message.t]
  @callback recipients() :: [String.t]
  @callback clear() :: any
end
