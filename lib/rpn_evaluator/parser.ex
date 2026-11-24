defmodule RpnEvaluator.Parser do
  @moduledoc """
  Módulo de análisis léxico (Tokenizer / Lexer) para Notación Polaca Inversa.
  Tokeniza la entrada del usuario separando por espacios y genera una secuencia
  de tokens tipados utilizando tuplas etiquetadas (tagged tuples).
  """

  alias RpnEvaluator.Types.Value

  @type token ::
    {:value, Value.t()}
    | {:operator, atom()}
    | {:identifier, String.t()}
    | {:command, atom()}

  @doc """
  Analiza una cadena de texto y retorna una lista de tokens o un error si encuentra
  un carácter o token no reconocible.
  """
  @spec parse(String.t()) :: {:ok, [token()]} | {:error, {:invalid_token, String.t()}}
  def parse(input) when is_binary(input) do
    tokens =
      input
      |> String.trim()
      |> String.split(~r/\s+/, trim: true)

    tokenize_tokens(tokens, [])
  end

  defp tokenize_tokens([], acc), do: {:ok, Enum.reverse(acc)}
  defp tokenize_tokens([raw | rest], acc) do
    case classify_token(raw) do
      {:ok, token} -> tokenize_tokens(rest, [token | acc])
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Clasifica un lexema individual en su correspondiente token estructurado.
  """
  @spec classify_token(String.t()) :: {:ok, token()} | {:error, {:invalid_token, String.t()}}
  def classify_token(token) do
    cond do
      token in ["+", "-", "*", "/", "==", "!=", "<", ">", "="] ->
        {:ok, {:operator, parse_operator(token)}}

      token in ["begin", "end", "vars", "stack", "clear", "help", "exit", "quit"] ->
        {:ok, {:command, String.to_atom(token)}}

      token == "true" ->
        {:ok, {:value, Value.new_boolean(true)}}

      token == "false" ->
        {:ok, {:value, Value.new_boolean(false)}}

      integer_string?(token) ->
        {:ok, {:value, Value.new_integer(String.to_integer(token))}}

      float_string?(token) ->
        {:ok, {:value, Value.new_float(String.to_float(token))}}

      identifier_string?(token) ->
        {:ok, {:identifier, token}}

      true ->
        {:error, {:invalid_token, token}}
    end
  end

  defp parse_operator("+"), do: :add
  defp parse_operator("-"), do: :sub
  defp parse_operator("*"), do: :mul
  defp parse_operator("/"), do: :div
  defp parse_operator("=="), do: :eq
  defp parse_operator("!="), do: :neq
  defp parse_operator("<"), do: :lt
  defp parse_operator(">"), do: :gt
  defp parse_operator("="), do: :assign

  defp integer_string?(str) do
    case Integer.parse(str) do
      {_int, ""} -> true
      _ -> false
    end
  end

  defp float_string?(str) do
    case Float.parse(str) do
      {_float, ""} -> true
      _ -> false
    end
  end

  defp identifier_string?(str) do
    # Identificador válido: inicia con letra o _ seguido de alfanuméricos
    Regex.match?(~r/^[a-zA-Z_][a-zA-Z0-9_]*$/, str)
  end
end
