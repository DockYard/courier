defmodule Courier.Adapters.TestTest do
  use ExUnit.Case

  @adapter Courier.Adapters.Test

  setup do
    {:ok, pid} =
      [Supervisor.Spec.supervisor(@adapter, [[]])]
      |> Supervisor.start_link(strategy: :one_for_one)

    {:ok, pid: pid}
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
    assert @adapter.messages() == []

    @adapter.deliver(@message1, [])
    @adapter.deliver(@message2, [])

    assert Enum.member?(@adapter.messages(), @message1)
    assert Enum.member?(@adapter.messages(), @message2)
  end

  test "find all unique recipients" do
    assert @adapter.recipients == []

    @adapter.deliver(@message1, [])
    @adapter.deliver(@message2, [])
    @adapter.deliver(@message3, [])

    assert length(@adapter.recipients()) == 3
    assert Enum.member?(@adapter.recipients(), "jack@example.com")
    assert Enum.member?(@adapter.recipients(), "jill@example.com")
    assert Enum.member?(@adapter.recipients(), "spider@example.com")
  end

  test "find all messages by recipient" do
    @adapter.deliver(@message1, [])
    @adapter.deliver(@message2, [])
    @adapter.deliver(@message3, [])

    messages = @adapter.messages_for("jack@example.com")

    assert Enum.member?(messages, @message1)
    refute Enum.member?(messages, @message2)
    assert Enum.member?(messages, @message3)
  end

  test "clean all emails" do
    @adapter.deliver(@message1, [])
    @adapter.deliver(@message2, [])

    assert length(@adapter.messages()) == 2

    @adapter.clear()

    assert length(@adapter.messages()) == 0
  end

  test "deleting an email" do
    @adapter.deliver(@message1, [])
    @adapter.deliver(@message2, [])

    assert length(@adapter.messages()) == 2

    @adapter.delete(@message1)

    messages = @adapter.messages()
    assert length(messages) == 1
    assert messages == [@message2]
  end

  test "deliverying will send a message to the `sent_from` pid" do
    @adapter.deliver(@message1, [sent_from: self()])

    assert_receive {:delivered, @message1}
  end
end
