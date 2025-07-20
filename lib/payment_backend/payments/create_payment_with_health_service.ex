defmodule PaymentBackend.Payments.CreatePaymentWithHealthService do
  use Oban.Worker, queue: :create_payment_with_health_service

  alias PaymentBackend.Payments
  alias PaymentBackend.Payments.PaymentProcessorHealth

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    case PaymentProcessorHealth.get_health_service() do
      nil ->
        {:error, "No available payment service"}

      service ->
        Payments.create_payment(params, service)
    end
  end
end
