defmodule Courier.Adapters.AgentTest do
  use ExUnit.Case

  defmodule MockAdapter do
    use Courier.Adapters.Agent
  end

  setup do
    MockAdapter.init([])
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

  test "will store messages in ets when delivered" do
    assert MockAdapter.messages() == []

    MockAdapter.deliver(@message1, %{})
    MockAdapter.deliver(@message2, %{})

    assert Enum.member?(MockAdapter.messages(), @message1)
    assert Enum.member?(MockAdapter.messages(), @message2)
  end

  test "find all unique recipients" do
    assert MockAdapter.recipients == []

    MockAdapter.deliver(@message1, %{})
    MockAdapter.deliver(@message2, %{})
    MockAdapter.deliver(@message3, %{})

    assert length(MockAdapter.recipients()) == 3
    assert Enum.member?(MockAdapter.recipients(), "jack@example.com")
    assert Enum.member?(MockAdapter.recipients(), "jill@example.com")
    assert Enum.member?(MockAdapter.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    MockAdapter.deliver(@message1, %{})
    MockAdapter.deliver(@message2, %{})
    MockAdapter.deliver(@message3, %{})

    messages = MockAdapter.messages_for("jack@example.com")

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
    assert Enum.member?(messages, @message3)
  end

  test "clean all emails" do
    MockAdapter.deliver(@message1, %{})
    MockAdapter.deliver(@message2, %{})

    assert length(MockAdapter.messages()) == 2

    MockAdapter.clear()

    assert length(MockAdapter.messages()) == 0
  end
end
