defmodule PaymentBackend.Payments.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "payments" do
    field(:correlation_id, :string)
    field(:amount, :float)
    field(:requested_at, :utc_datetime)
    field(:service, Ecto.Enum, values: [:default, :fallback])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%__MODULE__{} = payment, attrs) do
    payment
    |> cast(attrs, [:correlation_id, :amount])
    |> validate_required([:correlation_id, :amount])
    |> put_change(:requested_at, DateTime.truncate(DateTime.utc_now(), :second))
    |> validate_uui(:correlation_id)
    |> unique_constraint(:correlation_id)
  end

  defp validate_uui(changeset, field) do
    changeset
    |> get_field(field)
    |> Ecto.UUID.cast()
    |> case do
      {:ok, _} -> changeset
      :error -> add_error(changeset, field, "must be a valid UUID")
    end
  end
end
