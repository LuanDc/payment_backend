defmodule PaymentBackend.Payments do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi

  alias PaymentBackend.Payments.{
    CreatePaymentWorker,
    CreatePaymentWithHealthService,
    Payment,
    PaymentProcessorHealth
  }

  alias PaymentBackend.Repo

  def get_payment_by!(opts \\ []), do: Repo.get_by!(Payment, opts)

  def get_payments_summary(from: from, to: to, service: service) do
    query =
      from(p in Payment,
        where: p.service == ^service,
        where: p.requested_at >= ^from and p.requested_at <= ^to,
        select: %{
          total_amount: coalesce(sum(p.amount), 0),
          total_requests: count(p.correlation_id)
        }
      )

    Repo.one(query)
  end

  def create_payment(params) do
    case PaymentProcessorHealth.get_health_service() do
      nil ->
        params
        |> CreatePaymentWithHealthService.new()
        |> Oban.insert()

      service ->
        create_payment(params, service)
    end
  end

  def create_payment(params, service) do
    Multi.new()
    |> Multi.insert(:payments, Payment.changeset(%Payment{}, params))
    |> Multi.insert(:oban_jobs, fn _ ->
      params = Map.put_new(params, "service", service)
      CreatePaymentWorker.new(params)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{payments: payment}} -> {:ok, payment}
      {:error, :payments, changeset, _} -> {:error, changeset}
      {:error, :oban_jobs, error, _} -> {:error, error}
    end
  end
end
