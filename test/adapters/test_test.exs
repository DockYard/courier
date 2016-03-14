defmodule Courier.Adapters.TestTest do
  use ExUnit.Case

  setup do
    Courier.Adapters.Test.init([])
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
    assert Courier.Adapters.Test.messages() == []

    Courier.Adapters.Test.deliver(@message1, %{})
    Courier.Adapters.Test.deliver(@message2, %{})

    assert Enum.member?(Courier.Adapters.Test.messages(), @message1)
    assert Enum.member?(Courier.Adapters.Test.messages(), @message2)
  end

  test "find all unique recipients" do
    assert Courier.Adapters.Test.recipients == []

    Courier.Adapters.Test.deliver(@message1, %{})
    Courier.Adapters.Test.deliver(@message2, %{})
    Courier.Adapters.Test.deliver(@message3, %{})

    assert length(Courier.Adapters.Test.recipients()) == 3
    assert Enum.member?(Courier.Adapters.Test.recipients(), "jack@example.com")
    assert Enum.member?(Courier.Adapters.Test.recipients(), "jill@example.com")
    assert Enum.member?(Courier.Adapters.Test.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    Courier.Adapters.Test.deliver(@message1, %{})
    Courier.Adapters.Test.deliver(@message2, %{})
    Courier.Adapters.Test.deliver(@message3, %{})

    messages = Courier.Adapters.Test.messages_for("jack@example.com")

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
    assert Enum.member?(messages, @message3)
  end

  test "clean all emails" do
    Courier.Adapters.Test.deliver(@message1, %{})
    Courier.Adapters.Test.deliver(@message2, %{})

    assert length(Courier.Adapters.Test.messages()) == 2

    Courier.Adapters.Test.clear()

    assert length(Courier.Adapters.Test.messages()) == 0
  end

  test "deleting an email" do
    Courier.Adapters.Test.deliver(@message1, %{})
    Courier.Adapters.Test.deliver(@message2, %{})

    assert length(Courier.Adapters.Test.messages()) == 2
    
    Courier.Adapters.Test.delete(@message1)

    messages = Courier.Adapters.Test.messages()
    assert length(messages) == 1
    assert messages == [@message2]
  end
end
