defmodule Courier do
  @moduledoc """
  This module is `use`ed by your custom mailer.

  ## Example:

      defmodule MyApp.Mailer do
        use Courier, otp_app: :my_app
      end
  """
  defmacro __using__(opts) do
    {_otp_app, adapter, config} = parse_config(__CALLER__.module, opts)

    # adapter.init(config)

    quote do
      use Supervisor
      import Courier

      # def start_link do
        # Supervisor.start_link(unquote(Macro.escpae(adapter)), :ok)
      # end
      def deliver(%Mail.Message{} = message),
        do: __adapter__.deliver(message, unquote(Macro.escape(config)))
      def __adapter__(),
        do: unquote(Macro.escape(adapter))
    end
  end

  @doc false
  def parse_config(mailer, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, mailer, [])
    adapter = config[:adapter]

    {otp_app, adapter, config}
  end

  @doc false
  def init_adapter(adapter, config) do
    adapter.init(config)
  end

  @doc """
  View rendering for mail parts

  Based upon the `template` extension the mail will have the proper `content-type` added.
  For example with the following:

      Courier.render(mail, MailerView, "user.html")

  `Courier` will use `Mail.put_html/2` once it has rendered the template.
  """
  def render(%Mail.Message{} = message, view, template, assigns = %{}) do
    body =
      view.render(template, assigns)
      |> case do
        {:safe, iodata} -> IO.iodata_to_binary(iodata)
        body when is_binary(body) -> body
      end

    case Path.extname(template) do
      ".html" -> Mail.put_html(message, body)
      ".txt" -> Mail.put_text(message, body)
    end
  end
end
