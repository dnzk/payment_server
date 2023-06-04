defmodule PaymentServer.Helpers.Macros do
  defmacro run_only_in_test(expression) do
    if Application.get_env(:payment_server, :test, false) do
      quote do
        unquote(expression)
      end
    end
  end
end
