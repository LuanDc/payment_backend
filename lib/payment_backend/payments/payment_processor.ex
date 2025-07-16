defmodule PaymentBackend.Payments.PaymentProcessor do
  require Logger

  def payments(payment, opts \\ []) do
    service = Keyword.get(opts, :service, :default)

    params =
      payment
      |> parse_payment()
      |> Poison.encode!()

    (payment_processor_url(service) <> "/payments")
    |> HTTPoison.post(params, [{"Content-Type", "application/json"}])
    |> handle_response()
  end

  def check_health(opts \\ []) do
    service = Keyword.get(opts, :service, :default)

    (payment_processor_url(service) <> "/payments/service-health")
    |> HTTPoison.get()
    |> handle_response()
  end

  defp parse_payment(payment) do
    %{
      "correlationId" => payment.correlation_id,
      "amount" => payment.amount,
      "requestedAt" => payment.requested_at
    }
  end

  defp payment_processor_url(:default),
    do: System.get_env("DEFAULT_SERVICE_URL", "http://localhost:8001")

  defp payment_processor_url(:fallback),
    do: System.get_env("FALLBACK_SERVICE_URL", "http://localhost:8002")

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}),
    do: {:ok, Poison.decode!(body)}

  defp handle_response({:ok, %HTTPoison.Response{status_code: 422, body: body}}) do
    {:error, body}
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 500} = error}) do
    {:error, error}
  end

  defp handle_response({:error, %HTTPoison.Error{} = error}) do
    {:error, error}
  end
end
