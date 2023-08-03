defmodule SoftEtherVpn.Client do
  @moduledoc false

  use GenServer

  # api

  @doc """
  ## Arguments

    - `dir_path` - path for execute directory of vpnclient, default: priv

  ### for custom.ini

    - `no_save_log` - default: false
    - `no_save_config` - default: false
    - `config_file_path` - default: `dir_path`/vpn_client.config
  """
  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def start_vpnclient(), do: GenServer.call(__MODULE__, :start)
  def stop_vpnclient(), do: GenServer.call(__MODULE__, :stop)
  def get_version(), do: GenServer.call(__MODULE__, :get_version)
  def list_account(), do: GenServer.call(__MODULE__, :list_account)
  def get_account_status(name), do: GenServer.call(__MODULE__, {:get_account_status, name})
  def enable_remote(), do: GenServer.call(__MODULE__, :enable_remote)
  def disable_remote(), do: GenServer.call(__MODULE__, :disable_remote)

  # state

  defmodule State do
    defstruct dir_path: "", bin_path: "", cmd_path: ""
  end

  # callbacks

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    dir_path = prepare_execute_dir(args)

    state =
      %State{
        dir_path: dir_path,
        bin_path: Path.join(dir_path, "vpnclient"),
        cmd_path: Path.join(dir_path, "vpncmd")
      }

    vpnclient!(state.bin_path, "start")

    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    vpnclient(state.bin_path, "stop")
  end

  @impl true
  def handle_info({:EXIT, _port, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:start, _from, state) do
    ret = vpnclient!(state.bin_path, "start")
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    ret = vpnclient!(state.bin_path, "stop")
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:get_version, _from, state) do
    ret = vpncmd!(state.cmd_path, "VersionGet")
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:list_account, _from, state) do
    ret = vpncmd!(state.cmd_path, "AccountList")
    {:reply, ret, state}
  end

  @impl true
  def handle_call({:get_account_status, name}, _from, state) do
    ret = vpncmd!(state.cmd_path, "AccountStatusGet #{name}")
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:enable_remote, _from, state) do
    ret = vpncmd!(state.cmd_path, "RemoteEnable")
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:disable_remote, _from, state) do
    ret = vpncmd!(state.cmd_path, "RemoteDisable")
    {:reply, ret, state}
  end

  # privates

  defp prepare_execute_dir(args) do
    Keyword.get(args, :dir_path, client_dir_path())
    |> Path.absname()
    |> tap(fn dir_path ->
      if not File.exists?(Path.join(dir_path, "vpnclient")) do
        File.mkdir_p!(dir_path)

        ~w"ReadMeFirst_License.txt hamcore.se2 vpnclient vpncmd"
        |> Enum.each(&File.cp!(Path.join(client_dir_path(), &1), Path.join(dir_path, &1)))
      end

      prepare_custom_ini(dir_path, args)
    end)
  end

  defp prepare_custom_ini(dir_path, args) do
    no_save_log =
      if Keyword.get(args, :no_save_log, false), do: "NoSaveLog true\n", else: ""

    no_save_config =
      if Keyword.get(args, :no_save_config, false), do: "NoSaveConfig true\n", else: ""

    config_path =
      if path = Keyword.get(args, :config_file_path, false),
        do: "ConfigPath #{Path.absname(path)}\n",
        else: ""

    binary = no_save_log <> no_save_config <> config_path

    if binary != "" do
      File.write!(Path.join(dir_path, "custom.ini"), binary, [:sync])
    end
  end

  defp client_dir_path() do
    Path.join([SoftEtherVpn.priv_path(), "vpnclient"])
  end

  defp vpnclient(bin_path, args, opts \\ []) do
    MuonTrap.cmd(bin_path, ~w"#{args}", opts)
    # WHY: use Process.sleep/1
    # vpnclient は値が返ることが処理完了を意味しないので 100 msec 待つ
    |> tap(fn _ -> Process.sleep(100) end)
  end

  defp vpnclient!(bin_path, args, opts \\ []) do
    {collectable, 0} = vpnclient(bin_path, args, opts)
    collectable
  end

  defp vpncmd(bin_path, args, opts) do
    MuonTrap.cmd(bin_path, ~w"/client localhost /cmd #{args}", opts)
  end

  defp vpncmd!(bin_path, args, opts \\ []) do
    {collectable, 0} = vpncmd(bin_path, args, opts)
    collectable
  end
end
