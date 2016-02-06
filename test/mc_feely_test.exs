defmodule McFeely.Test do
  use ExUnit.Case

  import Mock

  defmodule TestAdapter do
    def deliver(%McFeely.Message{}=_message, %{}=_config), do: nil
  end

  defmodule TestView do
    use McFeely.View, root: "test/fixtures/templates"

    def upcase(message), do: String.upcase(message)
  end

  Application.put_env(:test, McFeely.Test.MyMailer, %{
    adapter: TestAdapter
  })

  defmodule MyMailer do
    use McFeely, otp_app: :test
  end

  test "Using McFeely: parsing config" do
    assert MyMailer.__adapter__ == TestAdapter
  end

  test "composing a message" do
    assigns = [foo: "bar", to: "<First User> first@example.com", from: "<Second User> second@example.com", subject: "Test Email"]
    message = MyMailer.compose(TestView, "foobar.html", assigns)

    assert %McFeely.Message{} = message
    assert message[:to] == assigns[:to]
    assert message[:from] == assigns[:from]
    assert message[:subject] == assigns[:subject]
    assert message[:body] == "BAR Test Email\n"
  end

  test "delivering a message delegates to the adapter" do
    with_mock McFeely.Test.TestAdapter, [deliver: fn(_message, _config) -> "delivered" end] do
      McFeely.Test.MyMailer.deliver(%McFeely.Message{})

      assert called McFeely.Test.TestAdapter.deliver(%McFeely.Message{}, %{adapter: McFeely.Test.TestAdapter})
    end
  end
end
