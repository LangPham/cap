defmodule Cap.MixProject do
  use Mix.Project

  @source_url "https://github.com/LangPham/cap"
  @version "0.2.0"

  def project do
    [
      app: :cap,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description:
        "Cap is Central Authentication Plug for Phoenix, access control library with Role-based access control (RBAC) and Attribute-based access control (ABAC)",
      package: package(),

      # Docs
      name: "Cap",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README* LICENSE .formatter.exs),
      maintainers: ["LangPham"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Cap",
      source_url: @source_url,
      homepage_url: @source_url,
      logo: "guides/images/logo.svg",
      extras: [
        "README.md",
        "LICENSE"
      ]
    ]
  end
end
