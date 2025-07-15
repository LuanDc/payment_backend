defmodule PaymentBackend.Payments.CreatePaymentWorker do
  use Oban.Worker, queue: :create_payment

  alias PaymentBackend.Payments
  alias PaymentBackend.Payments.{PaymentProcessor, PaymentProcessorHealth}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"correlation_id" => correlation_id}}) do
    with payment <- Payments.get_by_correlation_id!(correlation_id),
         default_health <- PaymentProcessorHealth.check_default_health(),
         {:ok, _response} <- PaymentProcessor.payments(payment, service: health(default_health)),
         changeset <- Ecto.Changeset.change(payment, service: health(default_health)),
         {:ok, _payment} <- PaymentBackend.Repo.update(changeset),
         do: :ok
  end

  defp health(:ok), do: :default
  defp health(:failing), do: :fallback
end
