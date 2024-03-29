defmodule Wug.Thai.MixProject do
  use Mix.Project

  def project do
    [
      app: :wug_thai,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wug, git: "https://github.com/guitsaru/wug.git", branch: "main"}
    ]
  end
end
