defmodule McFeely.Test do
  use ExUnit.Case

  import Mock

  defmodule TestAdapter do
    def deliver(%Mail.Message{} = _message, %{} = _config),
      do: nil
  end

  defmodule TestView do
    use McFeely.View, root: "test/fixtures/templates"

    def upcase(message),
      do: String.upcase(message)
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

  test "delivering a message delegates to the adapter" do
    with_mock McFeely.Test.TestAdapter, [deliver: fn(_message, _config) -> "delivered" end] do
      McFeely.Test.MyMailer.deliver(%Mail.Message{})

      assert called McFeely.Test.TestAdapter.deliver(%Mail.Message{}, %{adapter: McFeely.Test.TestAdapter})
    end
  end
end
