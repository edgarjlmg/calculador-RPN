defmodule RpnEvaluator do
  @moduledoc """
  Punto de entrada principal para la biblioteca y aplicación del Evaluador RPN.
  Permite invocar el REPL interactivo o evaluar cadenas de expresiones programáticamente.
  """

  alias RpnEvaluator.{CLI, Parser, Evaluator}
  alias RpnEvaluator.Types.State

  @doc """
  Inicia el REPL interactivo de consola.
  """
  @spec start() :: :ok
  def start do
    CLI.main([])
  end

  @doc """
  Evalúa una cadena de caracteres en RPN sobre un estado dado o un nuevo estado inicial.
  Retorna `{:ok, new_state}` o `{:error, reason, state}`.
  """
  @spec eval_string(String.t(), State.t()) ::
          {:ok, State.t()} | {:error, any(), State.t()}
  def eval_string(input, state \\ State.new()) do
    with {:ok, tokens} <- Parser.parse(input) do
      Evaluator.eval_tokens(tokens, state)
    else
      {:error, reason} -> {:error, reason, state}
    end
  end
end
