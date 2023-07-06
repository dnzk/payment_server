defmodule PaymentServer.Helpers.Macros do
  defmacro run_only_in_test(expression) do
    if Application.get_env(:payment_server, :test, false) do
      quote do
        unquote(expression)
      end
    else
      quote do
        raise "Illegal function access"
      end
    end
  end
end
