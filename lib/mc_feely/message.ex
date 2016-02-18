defmodule McFeely.Message do
  defstruct subject: nil,
            to: nil,
            cc: nil,
            bcc: nil,
            from: nil,
            body: nil

  def build(params) do
    %__MODULE__{
      to: params[:to],
      from: params[:from],
      subject: params[:subject],
      body: params[:body]
    }
  end

  def fetch(data, key), do: {:ok, Map.get(data, key)}

  def all_recipients(message) do
    (message[:to] |> List.wrap()) ++
    (message[:cc] |> List.wrap()) ++
    (message[:bcc] |> List.wrap())
    |> Enum.uniq()
  end
end
