defmodule PaymentBackend.Payments.PaymentProcessorHealth do
  use GenServer

  alias PaymentBackend.Payments.PaymentProcessor
  alias PaymentBackend.ReplicatedCache

  @cache_key "payment_processor_default"

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def check_default_health do
    PaymentBackend.ReplicatedCache.get(@cache_key) || :ok
  end

  def insert_health_status(status) do
    ReplicatedCache.put(@cache_key, status)
  end

  def init(:ok) do
    send(self(), :check_health)
    {:ok, %{}}
  end

  def handle_info(:check_health, state) do
    if Node.self() == :master@localhost do
      case PaymentProcessor.check_health() do
        {:ok, %{"failing" => false}} -> insert_health_status(:ok)
        _ -> insert_health_status(:failing)
      end
    end

    Process.send_after(self(), :check_health, 5_000)
    {:noreply, state}
  end
end
