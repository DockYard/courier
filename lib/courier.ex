defmodule Courier do
  @moduledoc """
  This module is `use`ed by your custom mailer.

  ## Example:

      defmodule MyApp.Mailer do
        use Courier, otp_app: :my_app
      end
  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      {otp_app, adapter, config} = Courier.parse_config(__MODULE__, opts)

      import Courier
      @opt_app otp_app
      @adapter adapter
      @config config

      def deliver(%Mail.Message{} = message),
        do: __adapter__.deliver(message, @config)
      def __adapter__(),
        do: @adapter
    end
  end

  def parse_config(mailer, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, mailer, [])
    adapter = config[:adapter]

    {otp_app, adapter, config}
  end
end
