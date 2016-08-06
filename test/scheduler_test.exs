defmodule Courier.SchedulerTest do
  use ExUnit.Case, async: true
  require Logger

  @scheduler Courier.Scheduler

  defmodule DeliveryException do
    defexception message: "This error is expected, go about your business!"
  end

  defmodule Adapter do
    def start_link(_), do: :ignore
    def deliver(_message, opts) do
      send opts[:pid], :sent

      :ok
    end
  end

  defmodule BadAdapter do
    def start_link(_), do: :ignore
    def deliver(_message, _opts) do
      raise DeliveryException
    end
  end

  defmodule OtherAdapter do
    def start_link(_), do: :ignore
    def deliver(%Mail.Message{headers: %{state: :fail}}, opts) do
      send opts[:pid], :error
      raise DeliveryException
    end

    def deliver(%Mail.Message{body: body}, opts) do
      send opts[:pid], body

      :ok
    end
  end

  defmodule Store do
    use Courier.Stores.Agent
  end

  test "with default store can schedule a delivery in the future, will retrieve from store and send to adapter" do
    opts = [adapter: Adapter, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> @scheduler.deliver(opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "override the default store" do
    opts = [adapter: Adapter, store: Store, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> @scheduler.deliver(opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "override the interval" do
    opts = [adapter: Adapter, store: Store, interval: 100, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> @scheduler.deliver(opts)

    refute_receive :sent
    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "multiple messages in the queue" do
    opts = [adapter: Adapter, store: Store, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> @scheduler.deliver(opts)

    Mail.build()
    |> @scheduler.deliver(opts)

    Mail.build()
    |> @scheduler.deliver(opts)

    assert_receive :sent
    assert_receive :sent
    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end

  test "schedule to delivery in the future" do
    opts = [adapter: Adapter, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    future =
      :calendar.universal_time()
      |> :calendar.datetime_to_gregorian_seconds()
      |> Kernel.+(2)
      |> :calendar.gregorian_seconds_to_datetime()

    Mail.build()
    |> @scheduler.deliver([{:at, future} | opts])

    refute_receive :sent, 500
    assert_receive :sent, 2000
    refute_receive :sent

    Supervisor.stop(pid)
  end

  @tag :capture_log
  test "adapter fails for some reason" do
    opts = [adapter: BadAdapter, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> @scheduler.deliver(opts)

    refute_receive :sent

    Supervisor.stop(pid)
  end

  @tag :capture_log
  test "message causes failure for some reason" do
    opts = [adapter: OtherAdapter, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> Mail.Message.put_body("one")
    |> @scheduler.deliver(opts)

    Mail.build()
    |> Mail.Message.put_body("two")
    |> Mail.Message.put_header(:state, :fail)
    |> @scheduler.deliver(opts)

    Mail.build()
    |> Mail.Message.put_body("three")
    |> @scheduler.deliver(opts)

    assert_receive "one"
    assert_receive :error
    assert_receive "three"

    Supervisor.stop(pid)
  end

  test "ensures pool threads limit delivering overflows" do
    opts = [adapter: Adapter, pool_size: 1, interval: 50, pid: self()]

    {:ok, pid} =
      @scheduler.children(opts)
      |> Supervisor.start_link(strategy: :one_for_all)

    Mail.build()
    |> Mail.Message.put_body("one")
    |> @scheduler.deliver(opts)

    Mail.build()
    |> Mail.Message.put_body("two")
    |> @scheduler.deliver(opts)

    assert_receive :sent
    refute_receive :sent

    Supervisor.stop(pid)
  end
end
