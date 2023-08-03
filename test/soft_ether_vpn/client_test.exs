defmodule SoftEtherVpn.ClientTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  alias SoftEtherVpn.Client

  setup %{tmp_dir: tmp_dir} do
    pid = start_supervised!({Client, dir_path: Path.join(tmp_dir, "vpnclient")})

    %{pid: pid}
  end

  test "stop/0" do
    assert String.contains?(Client.stop(), "stopped")
  end

  test "stop/0 then start/0" do
    assert String.contains?(Client.stop(), "stopped")
    assert String.contains?(Client.start(), "started")
  end

  for f <- ["get_version", "list_account", "enable_remote", "disable_remote"] do
    test "#{f}/0 available" do
      apply(Client, :"#{unquote(f)}", [])
    end
  end

  @tag :skip
  test "get_account_status/1" do
    Client.get_account_status("test")
  end
end
