defmodule PaymentBackend.Payments.PaymentProcessorHealth do
  use GenServer

  alias PaymentBackend.Payments.PaymentProcessor
  alias PaymentBackend.ReplicatedCache

  @cache_key "payment_processor"

  def start_link(_state) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_health_status(:default), do: ReplicatedCache.get(@cache_key <> "_default")
  def get_health_status(:fallback), do: ReplicatedCache.get(@cache_key <> "_fallback")

  def get_health_service() do
    case ReplicatedCache.get(@cache_key <> "_default") do
      :ok ->
        :default

      :failing ->
        case ReplicatedCache.get(@cache_key <> "_fallback") do
          :ok -> :fallback
          :failing -> nil
        end
    end
  end

  def insert_health_status(service, status) do
    ReplicatedCache.put(@cache_key <> "_#{Atom.to_string(service)}", status)
  end

  def init(:ok) do
    send(self(), :check_health)
    {:ok, %{}}
  end

  def handle_info(:check_health, state) do
    if Node.self() == :payment_backend@apimaster do
      task = Task.async(fn -> handle_service_health_check(:default) end)
      handle_service_health_check(:fallback)
      Task.await(task, 500)
    end

    Process.send_after(self(), :check_health, 5_000)
    {:noreply, state}
  end

  defp handle_service_health_check(service) do
    case PaymentProcessor.check_health(service: service) do
      {:ok, %{"failing" => false, "minResponseTime" => delay}} when delay <= 4500 ->
        insert_health_status(service, :ok)

      {:ok, %{"failing" => _, "minResponseTime" => _}} ->
        insert_health_status(service, :failing)

      {:error, _} = error ->
        error
    end
  end
end
