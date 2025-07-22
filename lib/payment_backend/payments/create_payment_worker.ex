defmodule PaymentBackend.Payments.CreatePaymentWorker do
  use Oban.Worker, queue: :create_payment

  alias PaymentBackend.{Payments, Repo}
  alias PaymentBackend.Payments.{PaymentProcessor, PaymentProcessorHealth}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"correlation_id" => correlation_id, "service" => service}}) do
    with payment <- Payments.get_payment_by!(correlation_id: correlation_id),
         :ok <- get_health_status(String.to_atom(service)),
         {:ok, _response} <- make_payment(payment, String.to_atom(service)),
         changeset <- Ecto.Changeset.change(payment, service: String.to_atom(service)),
         {:ok, _payment} <- Repo.update(changeset),
         do: :ok
  end

  defp get_health_status(service) do
    case PaymentProcessorHealth.get_health_status(service) do
      :ok -> :ok
      :failing -> {:error, :failing}
    end
  end

  defp make_payment(payment, service) do
    case PaymentProcessor.payments(payment, service: service) do
      {:ok, response} ->
        {:ok, response}

      {:error,
       %{"message" => "Payment could not be processed. CorrelationId already exists:" <> _rest}} ->
        {:ok, "payment processed successfully"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
