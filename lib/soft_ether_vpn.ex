defmodule SoftEtherVpn do
  @moduledoc """
  Documentation for `SoftEtherVpn`.
  """

  def priv_path() do
    Application.app_dir(:soft_ether_vpn, "priv")
  end
end
