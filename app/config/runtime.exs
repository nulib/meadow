# Resolve app configurations using Hush
# If left to its own devices, Hush.resolve!/0 will try to configure all applications,
# including :kernel and :stdlib, which will output a warning. We can circumvent that
# by excluding them from the list of running applications.

unless Hush.release_mode?() do
  [:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)

  Application.loaded_applications()
  |> Enum.reject(fn {app, _, _} -> Enum.member?([:kernel, :stdlib], app) end)
  |> Enum.map(fn {app, _, _} -> {app, Application.get_all_env(app)} end)
  |> Hush.resolve!()
end
