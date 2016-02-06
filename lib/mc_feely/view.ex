defmodule McFeely.View do
  defmacro __using__(opts) do
    quote do
      import Phoenix.View
      use Phoenix.Template, root: Keyword.get(unquote(opts), :root)

      @view_resource String.to_atom(Phoenix.Naming.resource_name(__MODULE__, "View"))

      def __resource__, do: @view_resource
    end
  end
end
