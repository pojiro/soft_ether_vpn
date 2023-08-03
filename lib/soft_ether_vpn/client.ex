defmodule SoftEtherVpn.Client do
  use GenServer

  defmodule State do
    defstruct dir_path: "", bin_path: "", cmd_path: ""
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start(), do: GenServer.call(__MODULE__, :start)
  def stop(), do: GenServer.call(__MODULE__, :stop)
  def get_version(), do: GenServer.call(__MODULE__, :get_version)
  def list_account(), do: GenServer.call(__MODULE__, :list_account)
  def get_account_status(name), do: GenServer.call(__MODULE__, {:get_account_status, name})
  def enable_remote(), do: GenServer.call(__MODULE__, :enable_remote)
  def disable_remote(), do: GenServer.call(__MODULE__, :disable_remote)

  # callbacks

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    dir_path = Keyword.get(args, :dir_path, client_dir_path())

    if not File.exists?(Path.join(dir_path, "vpnclient")) do
      File.mkdir_p!(dir_path)

      ~w"ReadMeFirst_License.txt hamcore.se2 vpnclient vpncmd"
      |> Enum.each(&File.cp!(Path.join(client_dir_path(), &1), Path.join(dir_path, &1)))
    end

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
