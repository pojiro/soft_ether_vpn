defmodule SoftEtherVpn.MixProject do
  use Mix.Project

  def project do
    [
      app: :soft_ether_vpn,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, inets: :optional, ssl: :optional]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, "~> 0.1 or ~> 1.0"}
    ]
  end
end
