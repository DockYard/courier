defmodule Courier.Test.EtsTest do
  use ExUnit.Case

  setup do
    Courier.Adapters.ETS.new_table()
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
    assert Courier.Adapters.ETS.messages() == []

    Courier.Adapters.ETS.deliver(@message1, %{})
    Courier.Adapters.ETS.deliver(@message2, %{})

    assert Enum.member?(Courier.Adapters.ETS.messages(), @message1)
    assert Enum.member?(Courier.Adapters.ETS.messages(), @message2)
  end

  test "find all unique recipients" do
    assert Courier.Adapters.ETS.recipients == []

    Courier.Adapters.ETS.deliver(@message1, %{})
    Courier.Adapters.ETS.deliver(@message2, %{})
    Courier.Adapters.ETS.deliver(@message3, %{})

    assert length(Courier.Adapters.ETS.recipients()) == 3
    assert Enum.member?(Courier.Adapters.ETS.recipients(), "jack@example.com")
    assert Enum.member?(Courier.Adapters.ETS.recipients(), "jill@example.com")
    assert Enum.member?(Courier.Adapters.ETS.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    Courier.Adapters.ETS.deliver(@message1, %{})
    Courier.Adapters.ETS.deliver(@message2, %{})
    Courier.Adapters.ETS.deliver(@message3, %{})

    messages = Courier.Adapters.ETS.messages_for("jack@example.com")

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
    assert Enum.member?(messages, @message3)
  end

  test "clean all emails" do
    Courier.Adapters.ETS.deliver(@message1, %{})
    Courier.Adapters.ETS.deliver(@message2, %{})

    assert length(Courier.Adapters.ETS.messages()) == 2

    Courier.Adapters.ETS.clear()

    assert length(Courier.Adapters.ETS.messages()) == 0
  end
end
