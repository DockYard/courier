defmodule Courier.Scheduler do
  use GenServer

  @moduledoc """
  Scheduler adapter

  The Scheduler will allow you to schedule when messages can be sent out.
  It accomplishes this with three parts

  1. The adapter - needs to be set in the opts
  2. The poller - defaults to an `interval` of `1_000`ms
  3. The store - defaults to `Courier.Stores.Simple`
  4. The pool - maxx concurrent connections to the adapter at any given time

  ## The Adapter
  First you should create a new mailer that is unique from all other mailers.
  For example, you may call is `ScheduledMailer`. optsure it similar to other mailers,
  but be sure to use the `Courier.Scheduler` for the adapter.

      # lib/my_app/mailers/scheduled.ex
      defmodule MyApp.ScheduledMailer do
        use Courier, otp_ap: :my_app
      end

      #lib/my_app/mailers/default.ex
      defmodule MyApp.DefaultMailer do
        use Courier, otp_app: :my_app
      end

      # opts/dev.exs
      opts :my_app, MyApp.Mailer,
        adapter: Courier.Adapters.Logger

      # opts/opts.exs
      opts :my_app, MyApp.ScheduledMailer,
        adapter: Courier.Scheduler,
        mailer: MyApp.DefaultMailer

  To sent mail you just use `MyApp.ScheduledMailer.deliver/2`

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

  The scheduler will delegate the message sending to the `mailer` declared in yor ScheduledMailer's opts.

  ## The Poller

  The default polling interval is `0`. This is likely far too aggressive. To time interval for how frequently
  the poller awakes to check for new messages to send simply set `interval` in the opts:

      # opts/opts.exs
      opts :my_app, MyApp.Mailer,
        adapter: Courier.Adapter.Logger,
        interval: 1_000 * 60 * 60  # awakes once an hour

  The value for the interval is in milliseconds in accordance with the value that
  [`:timer.sleep/1`](http://erlang.org/doc/man/timer.html#sleep-1)  expects.

  ## Store

  The store is where messages are kept until they are ready to be sent. The default
  store is `Courier.Stores.Simple` and is just an Agent, storing messages in-memory.
  This may not be ideal for your use-case. You can override the store in the opts:

      # opts/opts.exs
      opts :my_app, MyApp.ScheduledMailer,
        adapter: Courier.Scheduler,
        mailer: MyApp.DefaultMailer,
        store: MyApp.OtherStore

  The custom store will need respond to a certain API. Please see the documentation for `Courier.Store`
  for details or look at the source code for `Courier.Stores.Agent`.
  """

  defmodule Worker do
    use GenServer

    def start_link(state) do
      GenServer.start_link(__MODULE__, state, [])
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:deliver, message}, _from, [store: store, adapter: adapter, opts: opts] = state) do
      store.delete(message)
      adapter.deliver(message, opts)

      {:noreply, state}
    end
  end

  @doc false
  def deliver(%Mail.Message{} = message, opts) do
    store(opts).put({message, timestamp(opts)})
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
      :poolboy.child_spec(opts[:pool_name], pool_opts(pool_name, opts), [store: store, adapter: adapter, opts: opts]),
      Supervisor.Spec.worker(store, []),
      Supervisor.Spec.worker(__MODULE__, [opts])
    ]
  end

  defp pool_opts(name, opts) do
    [
      name: {:local, name},
      worker_module: Worker,
      size: opts[:pool_size] || 10,
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
    state =
      store(opts).all(past: true)
      |> Enum.reduce(state, fn(message, state) ->
        %{ref: ref} = Task.Supervisor.async_nolink(opts[:task_sup], fn ->
          :poolboy.transaction(opts[:pool_name], fn(worker_pid) ->
            GenServer.call(worker_pid, {:deliver, message})
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
    do: opts[:interval] || 1000
end
