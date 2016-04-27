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
    assert Store.all(past: true) == []

    past = {{2010, 1, 1}, {0, 0, 0}}
    future = {{3000, 1, 1}, {0, 0, 0}}

    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, future})

    messages = Store.all(past: true)

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
  end

  test "all() will return all messages regardless of timestamp" do
    assert Store.all() == []

    past = {{2010, 1, 1}, {0, 0, 0}}
    future = {{3000, 1, 1}, {0, 0, 0}}

    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, future})

    messages = Store.all()

    assert Enum.member?(messages, @message1)
    assert Enum.member?(messages, @message2)
  end

  test "clear all emails" do
    past = {{2010, 1, 1}, {0, 0, 0}}
    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, past})

    assert length(Store.all()) == 2

    :ok = Store.clear()

    assert length(Store.all()) == 0
  end

  test "deleting a message" do
    past = {{2010, 1, 1}, {0, 0, 0}}
    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, past})

    assert length(Store.all()) == 2

    :ok = Store.delete(@message1)

    messages = Store.all()
    assert length(messages) == 1
    assert messages == [@message2]
  end

  test "deleting many messages" do
    past = {{2010, 1, 1}, {0, 0, 0}}
    :ok = Store.put({@message1, past})
    :ok = Store.put({@message2, past})
    :ok = Store.put({@message3, past})

    assert length(Store.all()) == 3

    :ok = Store.delete([@message1, @message2])

    messages = Store.all()
    assert length(messages) == 1
    assert messages == [@message3]
  end
end
