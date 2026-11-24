defmodule RpnEvaluator.Environment do
  @moduledoc """
  Implementación de la tabla de símbolos (entorno de variables) con soporte para:
  - Ámbitos léxicos anidados (Lexical Scoping).
  - Ocultamiento de variables (Variable Shadowing).
  - Bloques de alcance temporal (begin / end).
  - Inmutabilidad estricta y compartición estructural de memoria (BEAM).

  La estructura de datos utilizada es una lista enlazada de mapas:
      `[ current_local_scope | parent_scopes ]`
  donde el último elemento representa el entorno global.
  """

  alias RpnEvaluator.Types.Value

  @type scope :: %{String.t() => Value.t()}
  @type env :: [scope()]

  @doc """
  Inicializa un nuevo entorno que contiene únicamente el ámbito global (nivel 0).
  """
  @spec new() :: env()
  def new, do: [%{}]

  @doc """
  Abre un nuevo bloque de alcance local (`begin`).
  Agrega un nuevo mapa vacío a la cabeza de la lista de ámbitos.
  Complejidad O(1) gracias a la compartición de cabecera en listas enlazadas inmutables.
  """
  @spec push_scope(env()) :: env()
  def push_scope(scopes) when is_list(scopes), do: [%{} | scopes]

  @doc """
  Cierra el bloque local actual (`end`).
  Descarta el ámbito más reciente en O(1) restaurando los ámbitos circundantes.
  Retorna `{:error, :no_active_scope}` si se intenta cerrar el ámbito global.
  """
  @spec pop_scope(env()) :: {:ok, env()} | {:error, :no_active_scope}
  def pop_scope([_global_only]), do: {:error, :no_active_scope}
  def pop_scope([_local | rest]), do: {:ok, rest}
  def pop_scope([]), do: {:error, :no_active_scope}

  @doc """
  Vincula una variable en el ámbito activo (el más interno).
  Si la variable ya existía en un ámbito superior, se aplica 'shadowing'
  sin alterar el valor del ámbito padre.
  """
  @spec bind(env(), String.t(), Value.t()) :: env()
  def bind([current | rest], var_name, %Value{} = value) when is_binary(var_name) do
    [Map.put(current, var_name, value) | rest]
  end

  @doc """
  Busca el valor de una variable recorriendo los ámbitos desde el más interno
  hasta el global (resolución de alcance léxico de orden O(n) sobre profundidad de scopes).
  """
  @spec lookup(env(), String.t()) :: {:ok, Value.t()} | {:error, :unbound_variable}
  def lookup([], _var_name), do: {:error, :unbound_variable}
  def lookup([current_scope | rest], var_name) when is_binary(var_name) do
    case Map.fetch(current_scope, var_name) do
      {:ok, %Value{} = value} -> {:ok, value}
      :error -> lookup(rest, var_name)
    end
  end

  @doc """
  Devuelve la lista de todas las variables declaradas en todos los ámbitos activos,
  incluyendo su nombre, valor y nivel de anidamiento (0 = global).
  """
  @spec all_variables(env()) :: [{String.t(), Value.t(), non_neg_integer()}]
  def all_variables(scopes) when is_list(scopes) do
    depth_total = length(scopes) - 1

    scopes
    |> Enum.with_index()
    |> Enum.flat_map(fn {scope, idx} ->
      level = depth_total - idx
      Enum.map(scope, fn {name, val} -> {name, val, level} end)
    end)
    |> Enum.sort_by(fn {name, _val, level} -> {level, name} end)
  end

  @doc """
  Calcula el nivel actual de anidamiento (0 = ámbito global, 1..N = locales).
  """
  @spec nesting_level(env()) :: non_neg_integer()
  def nesting_level(scopes) when is_list(scopes), do: max(0, length(scopes) - 1)
end
