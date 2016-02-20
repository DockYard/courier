defmodule McFeely.Adapters.Logger do
  require Logger

  def deliver(%Mail.Message{} = message, config) do
    rendered_message = Mail.render(message, McFeely.Renderers.Logger)
    Logger.log(config[:level] || :info, rendered_message)
  end
end
