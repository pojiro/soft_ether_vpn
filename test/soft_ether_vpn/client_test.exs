defmodule SoftEtherVpn.ClientTest do
  use ExUnit.Case

  alias SoftEtherVpn.Client

  setup do
    pid = start_supervised!(Client)
    %{pid: pid}
  end

  test "stop/0" do
    Client.stop()
  end

  test "stop/0 then start/0" do
    Client.stop()
    Client.start()
  end

  for f <- ["get_version", "list_account", "enable_remote", "disable_remote"] do
    test "#{f}/0" do
      wait_port_available(30)
      apply(Client, :"#{unquote(f)}", [])
    end
  end

  @tag :skip
  test "get_account_status/1" do
    wait_port_available(30)
    Client.get_account_status("test")
  end

  defdelegate wait_port_available(msec), to: Process, as: :sleep
end
