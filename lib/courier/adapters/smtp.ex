defmodule Courier.Adapters.SMTP do
  @moduledoc """
  SMTP Adapter

  The built-in SMTP adapter is implemented with [`gen_smtp`](https://github.com/Vagabond/gen_smtp)

  When setting up the adapter the following options can be used

  - `relay` mail server host
  - `port` mail server port (defaults to `25` when `ssl` is `false`, defaults to `465` when `ssl` is `true`)
  - `ssl` connect with SSL (defaults to `false`)
  - `hostname` label for the `relay`
  - `username` username used for authentication
  - `password` password used for authentication
  """
  use Courier.Adapters.SMTPBase
end
