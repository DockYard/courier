defmodule McFeely.Test.MessageTest do
  use ExUnit.Case

  test "collects all unique recipients into a list" do
    message = %McFeely.Message{
      to: ["one@example.com", "two@example.com"],
      cc: ["three@example.com", "one@example.com"],
      bcc: ["four@example.com", "three@example.com"]
    }

    all_recipients = McFeely.Message.all_recipients(message)
    assert length(all_recipients) == 4
    assert Enum.member?(all_recipients, "one@example.com")
    assert Enum.member?(all_recipients, "two@example.com")
    assert Enum.member?(all_recipients, "three@example.com")
    assert Enum.member?(all_recipients, "four@example.com")
  end
end
