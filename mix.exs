defmodule RpnEvaluator.MixProject do
  use Mix.Project

  def project do
    [
      app: :rpn_evaluator,
      version: "0.1.0",
      elixir: "~> 1.14 or ~> 1.15 or ~> 1.16 or ~> 1.17 or ~> 1.18 or ~> 1.19 or ~> 1.20",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: RpnEvaluator.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
