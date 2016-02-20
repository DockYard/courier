defmodule McFeely.Adapters.ETS do
  def table_name, do: :mcfeely_ets_table

  def new_table do
    :ets.new(table_name(), [:named_table, :public])
  end

  def deliver(%Mail.Message{} = message, _config) do
    case :ets.lookup(table_name(), :messages) do
      [] -> :ets.insert(table_name(), {:messages, [message]})
      [{:messages, messages}] when is_list(messages) ->
        :ets.insert(table_name(), {:messages, [message|messages]})
    end
  end

  def messages do
    case :ets.lookup(table_name(), :messages) do
      [] -> []
      [{:messages, messages}] -> messages
    end
  end

  def messages_for(recipient) do
    Enum.filter messages(),
      &(Enum.member?(Mail.all_recipients(&1), recipient))
  end

  def recipients do
    Enum.reduce(messages(), [], &(Mail.all_recipients(&1) ++ &2))
    |> Enum.uniq()
  end

  def clear, do: :ets.delete(table_name(), :messages)
end
