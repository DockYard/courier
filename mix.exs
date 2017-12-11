defmodule Courier.Mixfile do
  use Mix.Project

  def project do
    [app: :courier,
     version: "0.1.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: [main: "Courier"],
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :gen_smtp, :poolboy, :mail]]
  end

  def description, do: "Adapter based email delivery"

  def package do
    [maintainers: ["Brian Cardarella"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/DockYard/courier"}
     ]
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
    [{:phoenix, "~> 1.1", only: :test},
     {:phoenix_html, "~> 2.2", only: :test},
     {:poolboy, "~> 1.5.0"},
     {:gen_smtp, "~> 0.11.0"},
     {:earmark, "~> 1.0.1", only: :dev},
     {:ex_doc, "~> 0.13.0", only: :dev},
     {:mail, "~> 0.2.0"}]
  end
end
