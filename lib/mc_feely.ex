defmodule McFeely do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {otp_app, adapter, config} = McFeely.parse_config(__MODULE__, opts)

      import McFeely
      @opt_app otp_app
      @adapter adapter
      @config config

      def deliver(%Mail.Message{} = message),
        do: __adapter__.deliver(message, @config)
      def __adapter__(),
        do: @adapter

      def compose(view, template, assigns \\ []) do
        body = Phoenix.View.render_to_string(view, template, assigns)

        List.insert_at(assigns, -1, {:body, body})
        |> McFeely.Message.build()
      end
    end
  end

  def parse_config(mailer, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, mailer, [])
    adapter = config[:adapter]

    {otp_app, adapter, config}
  end
end
