defmodule SoftEtherVpn.Build do
  @moduledoc """
  Documentation for `SoftEtherVpn.Build`.
  """

  require Logger

  def run() do
    for type <- types(), do: build(type)
  end

  def build(type) do
    if not File.exists?(file_path(type)), do: download(type)
    uncompress(type)
    modify_makefile(type)
    make(type)
    copy_to_priv(type)
  end

  def download(type) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    http_options =
      [
        ssl: [
          verify: :verify_peer,
          cacertfile: CAStore.file_path(),
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ],
          versions: protocol_versions()
        ]
      ]

    options = [body_format: :binary]

    url = url(type)

    Logger.debug("Downloading SoftEtherVPN from #{url}")

    binary =
      case :httpc.request(:get, {url, []}, http_options, options) do
        {:ok, {{_, 200, _}, _headers, body}} ->
          body

        other ->
          raise """
          Couldn't fetch #{url}: #{inspect(other)}
          """
      end

    File.write!(file_path(type), binary, [:binary, :sync])
  end

  def uncompress(type) do
    [cmd | args] =
      ~w"tar -xz --file #{file_path(type)} --directory #{src_path(type)} --strip-components 1"

    {_, 0} = System.cmd(cmd, args)
  end

  def modify_makefile(type) do
    makefile_path = Path.join(src_path(type), "Makefile")

    File.read!(makefile_path)
    |> String.split("\n")
    |> Enum.reject(&String.contains?(&1, "CC="))
    |> Enum.reject(&String.contains?(&1, "/cmd:Check"))
    |> Enum.join("\n")
    |> then(&File.write!(makefile_path, &1))
  end

  def make(type) do
    [cmd | args] = ~w"make --directory #{src_path(type)} main"
    {_, 0} = System.cmd(cmd, args)
  end

  def copy_to_priv(type) do
    ~w"#{type} vpncmd hamcore.se2 ReadMeFirst_License.txt"
    |> Enum.map(fn target ->
      [cmd | args] = ~w"cp -f #{Path.join(src_path(type), target)} #{priv_path(type)}"
      {_, 0} = System.cmd(cmd, args)
    end)
  end

  defp file_path(type) do
    "tmp" |> tap(&File.mkdir_p!/1) |> Path.join(file_name(type))
  end

  defp src_path(type) do
    Path.join("src", type) |> tap(&File.mkdir_p!/1)
  end

  defp priv_path(type) do
    Path.join("priv", type) |> tap(&File.mkdir_p!/1)
  end

  defp protocol_versions do
    if otp_version() < 25, do: [:"tlsv1.2"], else: [:"tlsv1.2", :"tlsv1.3"]
  end

  defp otp_version do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end

  defp url(type) do
    "https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/#{version()}/#{file_name(type)}"
  end

  defp file_name(type) do
    "softether-#{type}-#{version()}-#{release_date()}-#{target()}.tar.gz"
  end

  defp types() do
    Application.fetch_env!(:soft_ether_vpn, :types)
  end

  defp version() do
    Application.fetch_env!(:soft_ether_vpn, :version)
  end

  defp release_date() do
    Application.fetch_env!(:soft_ether_vpn, :release_date)
  end

  defp target() do
    case Mix.target() do
      :host -> "linux-x64-64bit"
      :rpi3 -> "linux-arm_eabi-32bit"
      :rpi4 -> "linux-arm64-64bit"
      _ -> Application.fetch_env!(:soft_ether_vpn, :target)
    end
  end
end
