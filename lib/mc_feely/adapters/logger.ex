defmodule McFeely.Adapters.Logger do
  require Logger

  def deliver(%McFeely.Message{}=message, config) do
    message = _render(message)
    Logger.log(config[:level] || :info, message)
  end

  defp _render(%McFeely.Message{}=message) do
    """
      Subject: #{message[:subject]}
      To: #{message[:to]}
      From: #{message[:from]}

      #{message[:body]}
    """
  end
end
