defmodule PaymentBackend.ReplicatedCache do
  use Nebulex.Cache,
    otp_app: :payment_backend,
    adapter: Nebulex.Adapters.Replicated,
    primary_storage_adapter: Nebulex.Adapters.Local
end
