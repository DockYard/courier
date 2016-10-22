defmodule Courier.Scheduler do
  use GenServer

  @timeout :infinity
  @pool_size 10
  @interval 1_000

  @moduledoc """
  Scheduler adapter

  The Scheduler will allow you to schedule when messages can be sent out.
  It accomplishes this with four parts

  1. The adapter - needs to be set in the opts
  2. The poller - defaults to an `interval` of `1_000`ms
  3. The store - defaults to `Courier.Stores.Simple`
  4. The pool - max concurrent deliveries through the adapter at any given time

  ## The Adapter
  All Mailers in Courier run through `Courier.Scheduler`. However, an adapter that scheduled
  messages are delivering through must be configured. Do this in your environment's config:

      # lib/my_app/mailer.ex
      defmodule MyApp.Mailer do
        use Courier, otp_ap: :my_app
      end

      # config/dev.exs
      config :my_app, MyApp.Mailer,
        adapter: Courier.Adapters.Logger

  To send mail you just use `MyApp.Mailer.deliver/2`

      Mail.build()
      |> MyApp.ScheduledMail.deliver()

  Courier will default to sending the email almost instantly. The assumed timestamp
  when sending is `:calendar.universal_time/0`. You can tell Courier when the message should be sent
  by passing the `at` option

      tomorrow =
        :calendar.universal_time()
        |> :calendar.datetime_to_gregorian_seconds()
        |> +(1 * 60 * 60 * 24) # 24 hours in seconds
        |> :calendar.gregorian_seconds_to_datetime()

      Mail.build()
      |> MyApp.ScheduledMail.deliver(at: tomorrow)

  The scheduler will delegate the message sending to the `mailer` declared in yor Mailer's opts.

  ## The Poller

  The default polling interval is `1_000`. This is likely far too aggressive. To change the interval for how frequently
  the poller awakes to check for new messages to send simply set `interval` in the opts:

      # opts/opts.exs
      opts :my_app, MyApp.Mailer,
        adapter: Courier.Adapter.Logger,
        interval: 1_000 * 60 * 60  # awakes once an hour

  The value for the interval is in milliseconds in accordance with the value that
  [`Process.send_after/3`](http://elixir-lang.org/docs/stable/elixir/Process.html#send_after/3)  expects.

  ## Store

  The store is where messages are kept until they are ready to be sent. The default
  store is `Courier.Stores.Simple` and is just an Agent, storing messages in-memory.
  This may not be ideal for your use-case. You can override the store in the opts:

      # opts/opts.exs
      opts :my_app, MyApp.Mailer,
        adapter: MyApp.DefaultMailer,
        store: MyApp.OtherStore

  The custom store must respond to a certain API. Please see the documentation for `Courier.Store`
  for details or look at the source code for `Courier.Stores.Agent`.

  ## Pool

  The number of concurrent messages being delivered by the adapter is limited with the pooler. By default this
  number is limited to 10. You can modify this in your environment's config:

      config :my_app, MyApp.Mailer
        adapter: Courier.Adapter.Logger,
        pool_size: 20

  If you are sending messages through an external service you should consult the documentation for that service
  to determine what the max concurrent connections allowed is.

  ## Special Options

  These are options that you may want to use in different environment

  * `delivery_timeout` milliseconds to keep the GenServer alive. This should be set to a much higher value
    in development and/or test environment.
  """

  defmodule Worker do
    use GenServer

    def start_link(state) do
      GenServer.start_link(__MODULE__, state, [])
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:deliver, message, message_opts}, _from, [store: _store, adapter: adapter, opts: _opts] = state) do
      adapter.deliver(message, message_opts)

      {:noreply, state}
    end
  end

  @doc false
  def deliver(%Mail.Message{} = message, opts) do
    store(opts).put({message, timestamp(opts), opts})
  end

  def children(opts) do
    mailer = opts[:mailer]
    adapter = opts[:adapter]
    store = store(opts)
    task_sup = Module.concat(mailer, TaskSupervisor)
    opts = Keyword.put(opts, :task_sup, task_sup)

    pool_name = Module.concat(mailer, Pool)
    opts = Keyword.put(opts, :pool_name, pool_name)

    [
      Supervisor.Spec.supervisor(Task.Supervisor, [[name: opts[:task_sup]]]),
      Supervisor.Spec.supervisor(adapter, [opts]),
      :poolboy.child_spec(opts[:pool_name], pool_opts(pool_name, opts), [store: store, adapter: adapter, opts: opts]),
      Supervisor.Spec.worker(store, []),
      Supervisor.Spec.worker(__MODULE__, [opts])
    ]
  end

  defp pool_opts(name, opts) do
    [
      name: {:local, name},
      worker_module: Worker,
      size: opts[:pool_size] || @pool_size,
      max_overflow: 0
    ]
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc false
  def init(opts) do
    state = %{opts: opts, messages: %{}}
    Process.send_after(self(), :poll, interval(opts))

    {:ok, state}
  end

  @doc false
  def handle_info(:poll, %{opts: opts} = state) do
    timeout = opts[:delivery_timeout] || @timeout
    state =
      store(opts).pop(past: true)
      |> Enum.reduce(state, fn({message, _timestamp, message_opts}, state) ->
        %{ref: ref} = Task.Supervisor.async_nolink(opts[:task_sup], fn ->
          :poolboy.transaction(opts[:pool_name], fn(worker_pid) ->
            GenServer.call(worker_pid, {:deliver, message, message_opts}, timeout)
          end)
        end)

        add_message(state, message, ref)
      end)

    Process.send_after(self(), :poll, interval(state.opts))

    {:noreply, state}
  end

  @doc false
  def handle_info({ref, :ok}, state) do
    {:noreply, delete_message(state, ref)}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, _pid, _}, state) do
    {:noreply, state}
  end

  defp add_message(%{messages: messages} = state, message, ref) do
    %{state | messages: Map.put(messages, ref, message)}
  end

  defp delete_message(%{messages: messages} = state, ref) do
    %{state | messages: Map.delete(messages, ref)}
  end

  defp timestamp(opts),
    do: opts[:at] || :calendar.universal_time()

  defp store(opts),
    do: opts[:store] || Courier.Stores.Simple

  defp interval(opts),
    do: opts[:interval] || @interval
end
