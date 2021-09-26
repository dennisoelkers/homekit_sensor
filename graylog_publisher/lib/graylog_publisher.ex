defmodule GraylogPublisher do
  use GenServer

  require Logger

  def start_link(options \\ %{}) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl true
  def init(options) do
    state = %{
      interval: options[:interval] || 10_000,
      graylog_url: options[:graylog_url],
      sensors: options[:sensors],
      measurements: :no_measurements
    }

    schedule_next_publish(state.interval)

    {:ok, state}
  end

  @impl true
  def handle_info(:publish_data, state) do
    {:noreply, state |> measure() |> publish()}
  end

  defp measure(state) do
    measurements =
      Enum.map(state.sensors, fn sensor ->
        sensor.read.() |> sensor.convert.()
      end)

    %{state | measurements: measurements}
  end

  defp prefix_keys(values) do
    for {k, v} <- values, into: %{}, do: { "_#{k}", v}
  end

  defp publish(state) do
    Enum.map(state.measurements, fn reading ->
      Logger.debug("Publishing #{inspect(reading)}")
      [source, values] = reading
      payload = Map.merge(%{
        version: "1.1",
        host: "sensor_hub",
        facility: source,
        level: 1,
        short_message: Jason.encode!(values),
        }, prefix_keys(values))
      Logger.debug("Sending #{inspect(Jason.encode!(payload))}")
      result =
        :post
        |> Finch.build(
          state.graylog_url,
          [{"Content-Type", "application/json"}],
          Jason.encode!(payload)
        )
        |> Finch.request(GraylogClient)

      Logger.debug("Server response: #{inspect(result)}")
      end)

    schedule_next_publish(state.interval)

    state
  end

  defp schedule_next_publish(interval) do
    Process.send_after(self(), :publish_data, interval)
  end
end
