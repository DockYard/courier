defmodule Courier.Stores.AgentTest do
  use ExUnit.Case

  defmodule Store do
    use Courier.Stores.Agent
  end

  setup_all do
    Store.start_link()

    :ok
  end

  setup do
    Store.clear()

    :ok
  end

  @message1 Mail.build()
            |> Mail.put_subject("Let's go up the hill!")
            |> Mail.put_to("jack@example.com")
            |> Mail.put_from("jill@example.com")
            |> Mail.put_text("To fetch a pail of water")

  @message2 Mail.build()
            |> Mail.put_subject("Let's go down the hill!")
            |> Mail.put_to("jill@example.com")
            |> Mail.put_from("jack@example.com")
            |> Mail.put_text("To fetch a pail of water")

  @message3 Mail.build()
            |> Mail.put_subject("Let's Dance!")
            |> Mail.put_to([{"Jack", "jack@example.com"}, "spider@example.com"])
            |> Mail.put_from("jill@example.com")
            |> Mail.put_text("To annoy the adults!")

  test "will store messages in agent with the given timestamp, only retrieves messages in the past" do
    assert Store.pop(past: true) == []

    past = {{2010, 1, 1}, {0, 0, 0}}
    future = {{3000, 1, 1}, {0, 0, 0}}

    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, future})

    messages = Store.pop(past: true)

    assert Enum.member?(messages, {@message1, past, []})
    refute Enum.member?(messages, {@message2, future, []})

    assert Store.pop(past: true) == []
  end

  test "pop() will return all messages regardless of timestamp" do
    assert Store.pop() == []

    past = {{2010, 1, 1}, {0, 0, 0}}
    future = {{3000, 1, 1}, {0, 0, 0}}

    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, future})

    messages = Store.pop()

    assert Enum.member?(messages, {@message1, past, []})
    assert Enum.member?(messages, {@message2, future, []})

    assert Store.pop() == []
  end

  test "put/3 can take options that are stored with the message" do
    assert Store.pop() == []

    past = {{2010, 1, 1}, {0, 0, 0}}

    :ok = Store.put({@message1, past, [foo: :bar]})

    messages = Store.pop()

    assert Enum.member?(messages, {@message1, past, [foo: :bar]})
  end
end
