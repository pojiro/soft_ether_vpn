defmodule SoftEtherVpn do
  @moduledoc """
  Documentation for `SoftEtherVpn`.
  """

  def client_dir_path() do
    Path.join([priv_path(), "vpnclient"])
  end

  def priv_path() do
    Application.app_dir(:soft_ether_vpn, "priv")
  end
end
