defmodule McFeely.Test.EtsTest do
  use ExUnit.Case

  setup do
    McFeely.Adapters.ETS.new_table()
    {:ok, %{}}
  end

  @message1 %McFeely.Message{
    subject: "Let's go up the hill!",
    to: "jack@example.com",
    from: "jill@example.com",
    body: "To fetch a pail of water!"
  }

  @message2 %McFeely.Message{
    subject: "Let's go down the hill!",
    to: "jill@example.com",
    from: "jack@example.com",
    body: "To fetch a pail of water!"
  }

  @message3 %McFeely.Message{
    subject: "Let's Dance!",
    to: ["jack@example.com", "spider@example.com"],
    from: "jill@example.com",
    body: "To annoy the adults!"
  }

  test "will store messages in ets when delivered" do
    assert McFeely.Adapters.ETS.messages() == []

    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})

    assert Enum.member?(McFeely.Adapters.ETS.messages(), @message1)
    assert Enum.member?(McFeely.Adapters.ETS.messages(), @message2)
  end

  test "find all unique recipients" do
    assert McFeely.Adapters.ETS.recipients == []

    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})
    McFeely.Adapters.ETS.deliver(@message3, %{})

    assert length(McFeely.Adapters.ETS.recipients()) == 3
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), @message1[:to])
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), @message2[:to])
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})
    McFeely.Adapters.ETS.deliver(@message3, %{})

    messages = McFeely.Adapters.ETS.messages_for(@message1[:to])

    assert Enum.member?(messages, @message1)
    assert Enum.member?(messages, @message3)
    refute Enum.member?(messages, @message2)
  end

  test "clean all emails" do
    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})

    assert length(McFeely.Adapters.ETS.messages()) == 2

    McFeely.Adapters.ETS.clear()

    assert length(McFeely.Adapters.ETS.messages()) == 0
  end
end
