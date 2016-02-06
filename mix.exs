defmodule McFeely.Mixfile do
  use Mix.Project

  def project do
    [app: :mc_feely,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :phoenix, :gen_smtp]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:phoenix, "~> 1.1"},
     {:phoenix_html, "~> 2.2"},
     {:gen_smtp, "0.9.0"},
     {:mock, "0.1.1", only: :test}]
  end
end
