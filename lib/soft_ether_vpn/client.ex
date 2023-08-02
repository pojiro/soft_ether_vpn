defmodule SoftEtherVpn.Client do
  use GenServer

  defmodule State do
    defstruct cd: SoftEtherVpn.priv_path()
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

    cd = Keyword.get(args, :cd, SoftEtherVpn.priv_path())
    state = %State{cd: cd}

    vpnclient!("start", cd: state.cd)

    {:ok, state}
  end

  @impl true
  def terminate(_reason, state) do
    vpnclient("stop", cd: state.cd)
  end

  @impl true
  def handle_info({:EXIT, _port, :normal}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:start, _from, state) do
    ret = vpnclient!("start", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    ret = vpnclient!("stop", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:get_version, _from, state) do
    ret = vpncmd!("VersionGet", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:list_account, _from, state) do
    ret = vpncmd!("AccountList", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call({:get_account_status, name}, _from, state) do
    ret = vpncmd!("AccountStatusGet #{name}", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:enable_remote, _from, state) do
    ret = vpncmd!("RemoteEnable", cd: state.cd)
    {:reply, ret, state}
  end

  @impl true
  def handle_call(:disable_remote, _from, state) do
    ret = vpncmd!("RemoteDisable", cd: state.cd)
    {:reply, ret, state}
  end

  # privates

  defp vpnclient(args, opts) do
    bin_path = Path.join(SoftEtherVpn.client_dir_path(), "vpnclient")
    MuonTrap.cmd(bin_path, ~w"#{args}", opts)
  end

  defp vpnclient!(args, opts) do
    {collectable, 0} = vpnclient(args, opts)
    collectable
  end

  defp vpncmd(args, opts) do
    bin_path = Path.join(SoftEtherVpn.client_dir_path(), "vpncmd")
    MuonTrap.cmd(bin_path, ~w"/client localhost /cmd #{args}", opts)
  end

  defp vpncmd!(args, opts) do
    {collectable, 0} = vpncmd(args, opts)
    collectable
  end
end
