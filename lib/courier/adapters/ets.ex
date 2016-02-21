defmodule Courier.Adapters.ETS do
  @moduledoc """
  Stores messages in ETS
  """
  def table_name, do: :courier_ets_table

  def new_table do
    :ets.new(table_name(), [:named_table, :public])
  end

  @doc """
  Delivers the message by storing on ETS
  """
  def deliver(%Mail.Message{} = message, _config) do
    case :ets.lookup(table_name(), :messages) do
      [] -> :ets.insert(table_name(), {:messages, [message]})
      [{:messages, messages}] when is_list(messages) ->
        :ets.insert(table_name(), {:messages, [message|messages]})
    end
  end

  @doc """
  Returns a list of all messages in ETS

  Returns an empty list if no messages are found
  """
  def messages do
    case :ets.lookup(table_name(), :messages) do
      [] -> []
      [{:messages, messages}] -> messages
    end
  end

  @doc """
  Returns a list of all messages for the given recipient

      Courier.Adapters.ETS.messages_for("joe@example.com")
      [%Mail.Message{...}, %Mail.Message{...}]
  """
  def messages_for(recipient) do
    Enum.filter messages(),
      &(Enum.member?(Mail.all_recipients(&1), recipient))
  end

  @doc """
  Unique list of all recipients for all messages

  Will include `BCC` recipients

      Courier.Adapters.ETS.all_recipients()
      ["joe@example.com", {"Brian", "brian@example.com"}]
  """
  def recipients do
    Enum.reduce(messages(), [], &(Mail.all_recipients(&1) ++ &2))
    |> Enum.uniq()
  end

  @doc """
  Clears all messages
  """
  def clear(),
    do: :ets.delete(table_name(), :messages)
end
