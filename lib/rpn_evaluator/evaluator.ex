defmodule RpnEvaluator.Evaluator do
  @moduledoc """
  Motor de evaluación en Notación Polaca Inversa (RPN) basada en pila.
  Demuestra los principios centrales de diseño en Elixir:
  1. Inmutabilidad: La pila y el entorno nunca mutan; cada operación retorna un nuevo estado.
  2. Paso explícito de parámetros: Las subrutinas reciben `(tokens, stack, env)` explícitamente.
  3. Chequeo dinámico y fuerte de tipos: Distinción estricta de tipos numéricos y booleanos.
  4. Manejo funcional de errores: Retorno consistente de tuplas `{:ok, ...}` y `{:error, ...}`.
  """

  alias RpnEvaluator.Types.{Value, State}
  alias RpnEvaluator.Environment

  @doc """
  Evalúa una lista de tokens sobre el estado actual (pila y entorno pasados explícitamente).
  Retorna `{:ok, new_state}` o `{:error, reason, original_state}`.
  """
  @spec eval_tokens([RpnEvaluator.Parser.token()], State.t()) ::
          {:ok, State.t()} | {:error, any(), State.t()}
  def eval_tokens([], %State{stack: stack, env: env} = state) do
    # Resolver referencias pendientes que quedaron en la pila (ej: el usuario evaluó solo 'x')
    case resolve_stack(stack, env, []) do
      {:ok, resolved_stack} ->
        {:ok, %State{state | stack: resolved_stack}}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  def eval_tokens([token | rest], %State{} = state) do
    case eval_step(token, state) do
      {:ok, %State{} = next_state} ->
        eval_tokens(rest, next_state)

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  # =========================================================================
  # Evaluación de cada token individual (Paso de parámetros explícito)
  # =========================================================================

  # 1. Valores literales (enteros, flotantes, booleanos) -> apilar directamente
  defp eval_step({:value, %Value{} = val}, %State{stack: stack} = state) do
    {:ok, %State{state | stack: [val | stack]}}
  end

  # 2. Identificadores -> apilar como referencia simbólica pendiente
  defp eval_step({:identifier, name}, %State{stack: stack} = state) do
    {:ok, %State{state | stack: [{:var_ref, name} | stack]}}
  end

  # 3. Operador de Asignación Postfija '=' (ej: x 10 =)
  defp eval_step({:operator, :assign}, %State{stack: [raw_val, target | rest_stack], env: env} = state) do
    with {:ok, %Value{} = value} <- resolve_operand(raw_val, env),
         {:ok, var_name} <- extract_var_name(target) do
      new_env = Environment.bind(env, var_name, value)
      new_stack = [value | rest_stack]
      {:ok, %State{stack: new_stack, env: new_env}}
    end
  end

  defp eval_step({:operator, :assign}, %State{stack: stack}) when length(stack) < 2 do
    {:error, :stack_underflow}
  end

  # 4. Operadores Aritméticos (+, -, *, /)
  defp eval_step({:operator, op}, %State{stack: [b_raw, a_raw | rest_stack], env: env} = state)
       when op in [:add, :sub, :mul, :div] do
    with {:ok, %Value{} = b} <- resolve_operand(b_raw, env),
         {:ok, %Value{} = a} <- resolve_operand(a_raw, env),
         :ok <- check_numeric_types(op, a, b),
         {:ok, %Value{} = result} <- apply_arithmetic(op, a, b) do
      {:ok, %State{state | stack: [result | rest_stack]}}
    end
  end

  # 5. Operadores de Comparación Relacional (<, >, <=, >=)
  defp eval_step({:operator, op}, %State{stack: [b_raw, a_raw | rest_stack], env: env} = state)
       when op in [:lt, :gt, :lte, :gte] do
    with {:ok, %Value{} = b} <- resolve_operand(b_raw, env),
         {:ok, %Value{} = a} <- resolve_operand(a_raw, env),
         :ok <- check_numeric_types(op, a, b),
         {:ok, %Value{} = result} <- apply_relational(op, a, b) do
      {:ok, %State{state | stack: [result | rest_stack]}}
    end
  end

  # 6. Operadores de Igualdad Lógica (==, !=)
  defp eval_step({:operator, op}, %State{stack: [b_raw, a_raw | rest_stack], env: env} = state)
       when op in [:eq, :neq] do
    with {:ok, %Value{} = b} <- resolve_operand(b_raw, env),
         {:ok, %Value{} = a} <- resolve_operand(a_raw, env),
         :ok <- check_compatible_equality_types(op, a, b),
         {:ok, %Value{} = result} <- apply_equality(op, a, b) do
      {:ok, %State{state | stack: [result | rest_stack]}}
    end
  end

  defp eval_step({:operator, _op}, %State{stack: stack}) when length(stack) < 2 do
    {:error, :stack_underflow}
  end

  # 7. Comandos de Ámbito de Bloque: 'begin' y 'end'
  defp eval_step({:command, :begin}, %State{env: env} = state) do
    new_env = Environment.push_scope(env)
    {:ok, %State{state | env: new_env}}
  end

  defp eval_step({:command, :end}, %State{env: env} = state) do
    case Environment.pop_scope(env) do
      {:ok, new_env} ->
        {:ok, %State{state | env: new_env}}

      {:error, :no_active_scope} ->
        {:error, :no_active_scope}
    end
  end

  # 8. Comando de limpieza de pila 'clear'
  defp eval_step({:command, :clear}, %State{} = state) do
    {:ok, %State{state | stack: []}}
  end

  # 9. Otros comandos de inspección (vars, stack) que no alteran el flujo en este paso
  defp eval_step({:command, _cmd}, %State{} = state) do
    {:ok, state}
  end

  # =========================================================================
  # Verificación de Tipos y Ejecución Aritmética / Lógica
  # =========================================================================

  defp check_numeric_types(op, %Value{type: t1}, %Value{type: t2}) do
    if t1 in [:integer, :float] and t2 in [:integer, :float] do
      :ok
    else
      {:error, {:type_error, op, t1, t2}}
    end
  end

  defp check_compatible_equality_types(op, %Value{type: t1}, %Value{type: t2}) do
    # Igualdad permitida entre números (int con float) o entre booleanos
    cond do
      t1 in [:integer, :float] and t2 in [:integer, :float] ->
        :ok

      t1 == :boolean and t2 == :boolean ->
        :ok

      true ->
        {:error, {:type_error, op, t1, t2}}
    end
  end

  defp apply_arithmetic(:add, %Value{raw: a}, %Value{raw: b}), do: {:ok, wrap_number(a + b)}
  defp apply_arithmetic(:sub, %Value{raw: a}, %Value{raw: b}), do: {:ok, wrap_number(a - b)}
  defp apply_arithmetic(:mul, %Value{raw: a}, %Value{raw: b}), do: {:ok, wrap_number(a * b)}

  defp apply_arithmetic(:div, _a, %Value{raw: 0}), do: {:error, :division_by_zero}
  defp apply_arithmetic(:div, _a, %Value{raw: 0.0}), do: {:error, :division_by_zero}

  defp apply_arithmetic(:div, %Value{type: :integer, raw: a}, %Value{type: :integer, raw: b}) do
    if rem(a, b) == 0 do
      {:ok, Value.new_integer(div(a, b))}
    else
      {:ok, Value.new_float(a / b)}
    end
  end

  defp apply_arithmetic(:div, %Value{raw: a}, %Value{raw: b}) do
    {:ok, Value.new_float(a / b)}
  end

  defp apply_relational(:lt, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a < b)}
  defp apply_relational(:gt, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a > b)}
  defp apply_relational(:lte, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a <= b)}
  defp apply_relational(:gte, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a >= b)}

  defp apply_equality(:eq, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a == b)}
  defp apply_equality(:neq, %Value{raw: a}, %Value{raw: b}), do: {:ok, Value.new_boolean(a != b)}

  defp wrap_number(num) when is_integer(num), do: Value.new_integer(num)
  defp wrap_number(num) when is_float(num), do: Value.new_float(num)

  # =========================================================================
  # Resolución de Variables y Referencias Simbólicas
  # =========================================================================

  defp resolve_operand(%Value{} = val, _env), do: {:ok, val}
  defp resolve_operand({:var_ref, name}, env) do
    case Environment.lookup(env, name) do
      {:ok, %Value{} = val} -> {:ok, val}
      {:error, :unbound_variable} -> {:error, {:unbound_variable, name}}
    end
  end

  defp extract_var_name({:var_ref, name}) when is_binary(name), do: {:ok, name}
  defp extract_var_name(%Value{} = val), do: {:error, {:invalid_assignment_target, val}}
  defp extract_var_name(other), do: {:error, {:invalid_assignment_target, other}}

  defp resolve_stack([], _env, acc), do: {:ok, Enum.reverse(acc)}
  defp resolve_stack([%Value{} = val | rest], env, acc) do
    resolve_stack(rest, env, [val | acc])
  end
  defp resolve_stack([{:var_ref, name} | rest], env, acc) do
    case Environment.lookup(env, name) do
      {:ok, %Value{} = val} -> resolve_stack(rest, env, [val | acc])
      {:error, :unbound_variable} -> {:error, {:unbound_variable, name}}
    end
  end
end
