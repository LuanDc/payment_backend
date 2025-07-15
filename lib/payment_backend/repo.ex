defmodule PaymentBackend.Repo do
  use Ecto.Repo,
    otp_app: :payment_backend,
    adapter: Ecto.Adapters.Postgres
end
