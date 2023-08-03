defmodule SoftEtherVpn.ClientTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  alias SoftEtherVpn.Client

  describe "opts :dir_path" do
    setup %{tmp_dir: tmp_dir} do
      pid = start_supervised!({Client, dir_path: Path.join(tmp_dir, "vpnclient")})

      %{pid: pid}
    end

    test "stop_vpnclient/0" do
      assert String.contains?(Client.stop_vpnclient(), "stopped")
    end

    test "stop_vpnclient/0 then start_vpnclient/0" do
      assert String.contains?(Client.stop_vpnclient(), "stopped")
      assert String.contains?(Client.start_vpnclient(), "started")
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

  describe "opts no_save_log: " do
    test "false", %{tmp_dir: tmp_dir} do
      execute_dir_path = Path.join(tmp_dir, "vpnclient")

      start_supervised!({Client, dir_path: execute_dir_path, no_save_log: false})
      assert not File.exists?(Path.join(execute_dir_path, "custom.ini"))

      Client.stop_vpnclient()
      assert File.exists?(Path.join(execute_dir_path, "client_log"))
    end

    test "true", %{tmp_dir: tmp_dir} do
      execute_dir_path = Path.join(tmp_dir, "vpnclient")

      start_supervised!({Client, dir_path: execute_dir_path, no_save_log: true})
      assert File.exists?(Path.join(execute_dir_path, "custom.ini"))

      Client.stop_vpnclient()
      assert not File.exists?(Path.join(execute_dir_path, "client_log"))
    end
  end

  describe "opts no_save_config: " do
    test "false", %{tmp_dir: tmp_dir} do
      execute_dir_path = Path.join(tmp_dir, "vpnclient")

      start_supervised!({Client, dir_path: execute_dir_path, no_save_config: false})
      assert not File.exists?(Path.join(execute_dir_path, "custom.ini"))

      Client.stop_vpnclient()
      assert File.exists?(Path.join(execute_dir_path, "backup.vpn_client.config"))
    end

    test "true", %{tmp_dir: tmp_dir} do
      execute_dir_path = Path.join(tmp_dir, "vpnclient")

      start_supervised!({Client, dir_path: execute_dir_path, no_save_config: true})
      assert File.exists?(Path.join(execute_dir_path, "custom.ini"))

      Client.stop_vpnclient()
      assert not File.exists?(Path.join(execute_dir_path, "backup.vpn_client.config"))
    end
  end

  test "opts no_save_log: true, no_save_config: true", %{tmp_dir: tmp_dir} do
    execute_dir_path = Path.join(tmp_dir, "vpnclient")

    start_supervised!(
      {Client, dir_path: execute_dir_path, no_save_log: true, no_save_config: true}
    )

    assert File.exists?(Path.join(execute_dir_path, "custom.ini"))

    Client.stop_vpnclient()
    assert not File.exists?(Path.join(execute_dir_path, "client_log"))
    assert not File.exists?(Path.join(execute_dir_path, "backup.vpn_client.config"))
  end

  test "opts :config_file_path", %{tmp_dir: tmp_dir} do
    execute_dir_path = Path.join(tmp_dir, "vpnclient")
    config_file_path = Path.join(File.cwd!(), "test/support/fixtures/vpn_client.config")

    start_supervised!({Client, dir_path: execute_dir_path, config_file_path: config_file_path})
    assert File.exists?(Path.join(execute_dir_path, "custom.ini"))
    assert String.contains?(Client.list_account(), "example.com:443")
  end
end
