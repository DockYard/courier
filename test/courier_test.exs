defmodule Courier.Test do
  use ExUnit.Case

  import Mock

  defmodule TestAdapter do
    def deliver(%Mail.Message{} = _message, %{} = _config),
      do: nil
  end

  defmodule TestView do
    use Courier.View, root: "test/fixtures/templates"

    def upcase(message),
      do: String.upcase(message)
  end

  Application.put_env(:test, Courier.Test.MyMailer, %{
    adapter: TestAdapter
  })

  defmodule MyMailer do
    use Courier, otp_app: :test
  end

  test "Using Courier: parsing config" do
    assert MyMailer.__adapter__ == TestAdapter
  end

  test "delivering a message delegates to the adapter" do
    with_mock Courier.Test.TestAdapter, [deliver: fn(_message, _config) -> "delivered" end] do
      Courier.Test.MyMailer.deliver(%Mail.Message{})

      assert called Courier.Test.TestAdapter.deliver(%Mail.Message{}, %{adapter: Courier.Test.TestAdapter})
    end
  end
end
