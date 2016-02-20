defmodule McFeely.Test.EtsTest do
  use ExUnit.Case

  setup do
    McFeely.Adapters.ETS.new_table()
    {:ok, %{}}
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
            |> Mail.put_to(["jack@example.com", "spider@example.com"])
            |> Mail.put_from("jill@example.com")
            |> Mail.put_text("To annoy the adults!")

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
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), "jack@example.com")
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), "jill@example.com")
    assert Enum.member?(McFeely.Adapters.ETS.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})
    McFeely.Adapters.ETS.deliver(@message3, %{})

    messages = McFeely.Adapters.ETS.messages_for("jack@example.com")

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
    assert Enum.member?(messages, @message3)
  end

  test "clean all emails" do
    McFeely.Adapters.ETS.deliver(@message1, %{})
    McFeely.Adapters.ETS.deliver(@message2, %{})

    assert length(McFeely.Adapters.ETS.messages()) == 2

    McFeely.Adapters.ETS.clear()

    assert length(McFeely.Adapters.ETS.messages()) == 0
  end
end
