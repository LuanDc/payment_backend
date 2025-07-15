defmodule PaymentBackendWeb.PaymentController do
  use PaymentBackendWeb, :controller

  alias PaymentBackend.Payments

  def index(conn, %{"from" => from, "to" => to}) do
    default_summary = Payments.get_payments_summary(from: from, to: to, service: "default")

    task =
      Task.async(fn -> Payments.get_payments_summary(from: from, to: to, service: "fallback") end)

    fallback_summary = Task.await(task)
    json(conn, %{"default" => default_summary, "fallback" => fallback_summary})
  end

  def create(conn, %{"amount" => amount, "correlationId" => correlation_id}) do
    params = %{"amount" => amount, "correlation_id" => correlation_id}

    case Payments.create_payment(params) do
      {:ok, _response} ->
        conn
        |> put_status(:created)
        |> text("")

      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> text("Unprocessable Entity")
    end
  end
end
