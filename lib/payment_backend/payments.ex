defmodule PaymentBackend.Payments do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
  alias PaymentBackend.Payments.{CreatePaymentWorker, Payment}
  alias PaymentBackend.Repo

  def get_by_correlation_id!(correlation_id) when is_binary(correlation_id) do
    Repo.get_by!(Payment, correlation_id: correlation_id)
  end

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
    Multi.new()
    |> Multi.insert(:payments, Payment.changeset(%Payment{}, params))
    |> Multi.insert(:oban_jobs, CreatePaymentWorker.new(params))
    |> Repo.transaction()
    |> case do
      {:ok, %{payments: payment}} -> {:ok, payment}
      {:error, :payments, changeset, _} -> {:error, changeset}
      {:error, :oban_jobs, error, _} -> {:error, error}
    end
  end
end
