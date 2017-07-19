# Courier [![Build Status](https://secure.travis-ci.org/DockYard/courier.svg?branch=master)](http://travis-ci.org/DockYard/courier)

Mail delivery for Elixir

**[Courier is built and maintained by DockYard, contact us for expert Elixir and Phoenix consulting](https://dockyard.com/phoenix-consulting)**.

Courier is an OTP adapter-based mail delivery system for Elixir applications. It means serious business for sending emails.

![](http://i.imgur.com/2DPqwPw.jpg)

It depends upon [`Mail`](https://github.com/DockYard/elixir-mail) for composing the message.

First create your mailer:

```elixir
defmodule MyApp.Mailer do
  use Courier, otp_app: :my_app
end
```

After this we need to add the Courier Supervisor to your tree. For
example, if you are using in a Phoenix app you can edit `lib/my_app.ex`

```elixir
def start(_type, _args) do
  children = [
    supervisor(MyApp.Repo, []),
    supervisor(MyApp.Endpoint, []),

    # Mailer Supervisor
    supervisor(MyApp.Mailer, [])
  ]
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
  password: System.get_env("COURIER_PASSWORD")
```

More configuration options for each adapter is in the [Adapters](#Adapters) section.

Then you can compose and deliver the message:

```elixir
Mail.build_multipart()
|> Mail.put_to("friend@example.com")
|> Mail.put_from("me@example.com")
|> Mail.put_subject("How are things?")
|> Mail.put_text("Let's meet for drinks!")
|> Mail.put_html("<p>Let's meet for drinks!</p>")
|> MyApp.Mailer.deliver()
```

Courier will deliver the message through the adapter that is configured.

## Deliveries

All deliveries are pushed into a shceduler and sent out asynchronously.
Let's learn how to customize this scheduler

### Scheduling deliveries

By default if you do not specify a datetime to delivery `at` Courier
will mark the message for immediate delivery. But let's say we want to
schedule a specific datetime to send a message. You can do that with:

```elixir
MyApp.Mailer.deliver(message, at: datetime)
```

The `datetime` variable should conform to either an Erlang calendar
tuple `{{year, month, day}, {hour, minute, second}}`

### Pooling

Courier will use a pool to rate limit the number of concurrent messages
being sent. This is necessary if you are sending to services that hate
their own rate limits. The default pool size is `10`. If you'd like to
change this default you can simply modify when configuring your mailer:


```elixir
config :my_app, MyApp.Mailer,
  pool_size: 15
```

[Read more about the Scheduler, configuring it, and using
it.](https://hexdocs.pm/courier/Courier.Scheduler.html)


## Rendering with Phoenix Views

If you'd like to render the `text` or `html` parts with a Phoenix view
you should use `Courier.render/4`

```elixir
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
render as `[File content]`

Options:
- `level` the `Logger` level to send the message to (defaults to `:info`)

### Courier.Adapters.Test

Exposes the ETS adapter from a REST based API

### Courier.Adapters.Web

CourierWeb adds a web interface for viewing the messages sent. To use it
add the library to your `mix.exs` file.  For more information on this adapter please refer to
[CourierWeb](https://github.com/DockYard/courier_web)

### Writing your own adapter

Creating your own adapter is simple. The only functions necessary are
`start_link/1` and `deliver/2`

```elixir
defmodule MyApp.Adapters.Custom do
  def start_link(_opts), do: :ignore

  def deliver(%Mail.Message{} = message, opts) do
    # your customized mailer
  end
end
```

The `message` passed into `deliver/2` is not a rendered [RFC2822](https://www.ietf.org/rfc/rfc2822.txt) message.
If you need the rendered version you can use `mail` to render it:

```elixir
rendered_message = Mail.render(message, Mail.Renderers.RFC2822)
```

Please refer to the `mail` library to learn more about creating custom
message renderers.

Each adapter is treated as its own OTP supervisor within your mailer's
supervisor tree. This will give you the opportunity to create more
complex adapters with their own workers. Just override
`start_link/1` however you'd like. The configuration options declared
for your mailer within the given mix environment are passed in as the
argument.

## Authors ##

* [Brian Cardarella](http://twitter.com/bcardarella)

[We are very thankful for the many contributors](https://github.com/dockyard/courier/graphs/contributors)

## Versioning ##

This library follows [Semantic Versioning](http://semver.org)

## Looking for help with your Elixir project? ##

[At DockYard we are ready to help you build your next Elixir project](https://dockyard.com/phoenix-consulting). We have a unique expertise in Elixir and Phoenix development that is unmatched. [Get in touch!](https://dockyard.com/contact/hire-us)

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

