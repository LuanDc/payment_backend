defmodule PaymentBackend.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:correlation_id, :string, null: false)
      add(:amount, :float, null: false)
      add(:requested_at, :utc_datetime, null: false)
      add(:service, :string)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:payments, [:correlation_id]))
  end
end
