if !function_exported?(:Env, :prefix, 0),
  do: File.read!("lib/env.ex") |> Code.eval_string()
