# Courier

Mail delivery for Elixir

[![Build Status](https://secure.travis-ci.org/DockYard/courier.svg?branch=master)](http://travis-ci.org/DockYard/courier)

Courier is an adapter-based mail delivery system for Elixir applications. It depends upon `[Mail](https://github.com/DockYard/elixir-mail)`
for composing the message.

First create your mailer:

```elixir
defmodule MyApp.Mailer do
  use Courier, otp_app: :my_app
end
```

Next set the default adapter in `config/config.exs` or `config/{environment}.exs`:

```elixir
config :my_app, MyApp.Mailer,
  adapter: Courier.Adapters.SMTP,
  relay: "smtp.myserver.com",
  hostname: "my-mail-server",
  port: 2525,
  username: System.get_env("COURIER_USERNAME"),
  password: System.get_env("CORUIER_PASSWORD")
```

More configuration options for each adapter is in the [Adapters](#Adapter) section.

Then you can compose and deliver the message:

```elixir
message =
  Mail.build_multipart()
  |> Mail.put_to("friend@example.com")
  |> Mail.put_from("me@example.com")
  |> Mail.put_subject("How are things?")
  |> Mail.put_text("Let's meet for drinks!")
  |> Mail.put_html("<p>Let's meet for drinks!</p>")
  |> MyApp.Mailer.deliver()
```

Courier will deliver the message through the adapter that is configured.

## Rendering with Phoenix Views

If you'd like to render the `text` or `html` parts with a Phoenix view
you should use `Courier.render/4`

```
message =
  Mail.build_multipart()
  |> Mail.put_to("friend@example.com")
  |> Mail.put_from("me@example.com")
  |> Mail.put_subject("How are things?")
  |> Courier.render(MyApp.MailerView, "check_in.txt", user: user)
  |> Courier.render(MyApp.MailerView, "check_in.html", user: user)
  |> MyApp.Mailer.deliver()
```

`Courier.render/4` will parse the template path to determine the
expected `content-type`. For example, if your template is `foobar.html`
the assumed `content-type` is `text/html` and Courier will render the
template to a string and use `Mail.put_html(message, rendered_template)`

## Adapters

Courier comes with some built-in adapters

### Courier.Adapters.SMTP

The built-in SMTP adapter is implemented with [`gen_smtp`](https://github.com/Vagabond/gen_smtp)

Options:

- `relay` mail server host
- `port` mail server port (defaults to `25` when `ssl` is `false`, defaults to `465` when `ssl` is `true`)
- `ssl` connect with SSL (defaults to `false`)
- `hostname` label for the `relay`
- `username` username used for authentication
- `password` password used for authentication

### Courier.Adapters.Logger

Will write deliver all messages to the `Logger`. All attachment encoded data will 
rener as `[File content]`

Options:
- `level` the `Logger` level to send the message to (defaults to `:info`)

### Courier.Adapters.Test

Exposes the ETS adapter from a REST based API

### Courier.Adapters.Web

CourierWeb adds a web interface for viewing the messages sent. To use it
add the library to your `mix.exs` file.  For more information on this adapter please refer to
[CourierWeb](https://github.com/DockYard/courier_web)

## Authors ##

* [Brian Cardarella](http://twitter.com/bcardarella)

[We are very thankful for the many contributors](https://github.com/dockyard/courier/graphs/contributors)

## Versioning ##

This library follows [Semantic Versioning](http://semver.org)

## Looking for help with your Elixir project? ##

[At DockYard we are ready to help you build your next Elixir project](https://dockyard.com/phoenix-consulting). We have a unique expertise 
in Elixir and Phoenix development that is unmatched. [Get in touch!](https://dockyard.com/contact/hire-us)

At DockYard we love Elixir! You can [read our Elixir blog posts](https://dockyard.com/blog/categories/elixir)
or come visit us at [The Boston Elixir Meetup](http://www.meetup.com/Boston-Elixir/) that we organize.

## Want to help? ##

Please do! We are always looking to improve this library. Please see our
[Contribution Guidelines](https://github.com/dockyard/courier/blob/master/CONTRIBUTING.md)
on how to properly submit issues and pull requests.

## Legal ##

[DockYard](http://dockyard.com/), Inc. &copy; 2016

[@dockyard](http://twitter.com/dockyard)

[Licensed under the MIT license](http://www.opensource.org/licenses/mit-license.php)

