defmodule SensorHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SensorHub.Sensor

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SensorHub.Supervisor]

    children = children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: SensorHub.Worker.start_link(arg)
      # {SensorHub.Worker, arg},
    ]
  end

  def children(_target) do
    hap_server_config = %HAP.AccessoryServer{
      name: "Nerves Air Quality Sensor",
      identifier: "12:34:56:78:90:AB",
      accessory_type: 10,
      accessories: [
        %HAP.Accessory{
          name: "Air Quality Sensor",
          services: [
            %HAP.Services.AirQualitySensor {
              air_quality: {
                SensorHub.Homekit.AirQualitySensor,
                sensor: Sensor.new(SGP30)
              }
            },
            %HAP.Services.LightSensor {
              light_level: {
                SensorHub.Homekit.LightSensor,
                sensor: Sensor.new(VEML6030)
              }
            },
            %HAP.Services.HumiditySensor {
              current_relative_humidity: {
                SensorHub.Homekit.HumiditySensor,
                sensor: Sensor.new(BMP280)
              }
            },
            %HAP.Services.TemperatureSensor {
              temperature: {
                SensorHub.Homekit.TemperatureSensor,
                sensor: Sensor.new(BMP280)
              }
            }
          ]
        }
      ]
    }

    [
      {SGP30, []},
      {BMP280, [i2c_address: 0x77, name: BMP280]},
      {VEML6030, %{}},
      {Finch, name: GraylogClient},
      {
        GraylogPublisher,
        %{
          sensors: sensors(),
          graylog_url: graylog_url()
        }
      },
      {HAP, hap_server_config},
      SensorHub.Homekit.AirQualitySensor,
      SensorHub.Homekit.CarbonDioxideSensor,
      SensorHub.Homekit.CarbonDioxideLevel,
      SensorHub.Homekit.LightSensor,
      SensorHub.Homekit.HumiditySensor,
      SensorHub.Homekit.TemperatureSensor,
    ]
  end

  defp sensors do
    [Sensor.new(SGP30), Sensor.new(BMP280), Sensor.new(VEML6030)]
  end

  def target() do
    Application.get_env(:sensor_hub, :target)
  end

  def graylog_url() do
    "http://babbage:12201/gelf"
  end
end
