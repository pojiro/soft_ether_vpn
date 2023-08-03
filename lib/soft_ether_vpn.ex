defmodule SoftEtherVpn do
  @moduledoc """
  Documentation for `SoftEtherVpn`.
  """

  def priv_path() do
    Application.app_dir(:soft_ether_vpn, "priv")
  end

  # appcation callbacks

  use Application

  @impl true
  def start(_type, _args) do
    children = [] ++ maybe_vpnclient()

    opts = [strategy: :one_for_one, name: SoftEtherVpn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # privates

  defp maybe_vpnclient() do
    case Application.get_env(:soft_ether_vpn, :vpnclient) do
      nil -> []
      args -> [{SoftEtherVpn.Client, args}]
    end
  end
end
