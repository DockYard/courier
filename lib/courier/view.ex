defmodule Courier.View do
  @moduledoc """
  Write views meant for Courier deliveries

  Currently requires that `root` be set.

  ## Example:

      defmodule MyApp.Views.MailerView do
        use Courier.View, root: "web/templates/mailer"
      end
  """
  defmacro __using__(opts) do
    quote do
      import Phoenix.View
      use Phoenix.Template, root: Keyword.get(unquote(opts), :root)

      @view_resource String.to_atom(Phoenix.Naming.resource_name(__MODULE__, "View"))

      def __resource__, do: @view_resource
    end
  end
end
