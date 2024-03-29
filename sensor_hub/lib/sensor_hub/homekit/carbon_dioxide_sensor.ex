defmodule SensorHub.Homekit.CarbonDioxideSensor do
  @behaviour HAP.ValueStore
  use GenServer

  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl HAP.ValueStore
  def get_value(opts) do
    GenServer.call(__MODULE__, {:get, opts})
  end

  @impl HAP.ValueStore
  def put_value(value, opts) do
    GenServer.call(__MODULE__, {:put, value, opts})
  end

  @impl HAP.ValueStore
  def set_change_token(change_token, opts) do
    GenServer.call(__MODULE__, {:set_change_token, change_token, opts})
  end

  @impl GenServer
  def init(_) do
    state = %{}

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:get, sensor: sensor}, _from, state) do
    ["air_quality", %{ co2_eq_ppm: value }] = sensor.read.() |> sensor.convert.()

    Logger.info("Returning value of #{value}")

    {:reply, {:ok, value}, state}
  end

  @impl GenServer
  def handle_call({:put, value, sensor: sensor}, _from, state) do
    Logger.info("Writing value of #{value}")

    {:reply, state}
  end

  @impl GenServer
  def handle_call({:set_change_token, change_token, sensor: sensor}, _from, state) do
    {:reply, :ok, state}
  end
end
