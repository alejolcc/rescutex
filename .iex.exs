alias Rescutex.Repo

# If you have your own customization you'd like to include, you may add it to
# .iex.local.exs which will be ignored by git.
if File.exists?(".iex.local.exs") do
  Code.eval_file(".iex.local.exs")
end
