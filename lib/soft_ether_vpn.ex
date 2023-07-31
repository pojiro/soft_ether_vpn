defmodule SoftEtherVpn do
  @moduledoc """
  Documentation for `SoftEtherVpn`.
  """

  require Logger

  def prepare_make() do
    file_path = download()
    uncompress(file_path)
    modify_makefile(source_path())
  end

  def download() do
    type = "vpnbridge"
    version = "v4.41-9782-beta"
    release_date = "2022.11.17"
    target = "linux-x64-64bit"

    url =
      "https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/#{version}/softether-#{type}-#{version}-#{release_date}-#{target}.tar.gz"

    File.mkdir_p!("tmp")
    tar_gz_path = Path.join("tmp", Path.basename(URI.parse(url).path))

    # if not File.exists?(tar_gz_path) do
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

    Logger.debug("Downloading SoftEtherVPN from #{url}")

    tar_gz =
      case :httpc.request(:get, {url, []}, http_options, options) do
        {:ok, {{_, 200, _}, _headers, body}} ->
          body

        other ->
          raise """
          Couldn't fetch #{url}: #{inspect(other)}
          """
      end

    File.write!(tar_gz_path, tar_gz, [:binary, :sync])
    # end

    tar_gz_path
  end

  def uncompress(file_path) do
    [cmd | args] = ~w"tar -xz --file #{file_path} --directory src/ --strip-components 1"
    {_, 0} = System.cmd(cmd, args)
  end

  def modify_makefile(source_path) do
    makefile_path = Path.join(source_path, "Makefile")

    File.read!(makefile_path)
    |> String.split("\n")
    |> Enum.reject(&String.contains?(&1, "/cmd:Check"))
    |> Enum.join("\n")
    |> then(&File.write!(makefile_path, &1))
  end

  defp source_path() do
    "src"
  end

  defp protocol_versions do
    if otp_version() < 25, do: [:"tlsv1.2"], else: [:"tlsv1.2", :"tlsv1.3"]
  end

  defp otp_version do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end
end

SoftEtherVpn.prepare_make()
