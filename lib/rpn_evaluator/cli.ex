defmodule RpnEvaluator.CLI do
  @moduledoc """
  Interfaz interactiva de consola (REPL) para el Evaluador RPN.
  Gestiona la entrada y salida, el bucle de interacción (I/O loop),
  el formateo estético de datos y el reporte controlado de errores.
  """

  alias RpnEvaluator.{Parser, Evaluator, Environment}
  alias RpnEvaluator.Types.{Value, State}

  @spec main(list()) :: :ok
  def main(_args \\ []) do
    print_welcome_banner()
    initial_state = State.new()
    loop(initial_state)
  end

  @doc """
  Bucle recursivo de lectura-evaluación-impresión (REPL loop).
  La optimización de llamada terminal (Tail Call Optimization - TCO) en la BEAM
  garantiza que este bucle se ejecute indefinidamente sin agotar la pila de llamadas.
  """
  def loop(%State{} = state) do
    prompt = build_prompt(state)
    case IO.gets(prompt) do
      :eof ->
        IO.puts("\nSaliendo del REPL. ¡Hasta luego!")
        :ok

      {:error, reason} ->
        IO.puts("\nError al leer entrada: #{inspect(reason)}")
        :ok

      line ->
        trimmed = String.trim(line)
        handle_input(trimmed, state)
    end
  end

  defp handle_input(input, %State{} = state) do
    case String.downcase(input) do
      cmd when cmd in ["exit", "quit"] ->
        IO.puts("Saliendo del evaluador RPN. ¡Hasta luego!")
        :ok

      "" ->
        loop(state)

      "vars" ->
        print_variables(state.env)
        loop(state)

      "stack" ->
        print_stack(state.stack)
        loop(state)

      "clear" ->
        IO.puts("Pila vaciada.")
        loop(%State{state | stack: []})

      "help" ->
        print_help()
        loop(state)

      _other ->
        eval_expression(input, state)
    end
  end

  defp eval_expression(input, %State{} = state) do
    with {:ok, tokens} <- Parser.parse(input),
         {:ok, new_state} <- Evaluator.eval_tokens(tokens, state) do
      print_evaluation_result(new_state)
      loop(new_state)
    else
      {:error, reason, old_state} ->
        print_error(reason)
        loop(old_state)

      {:error, reason} ->
        print_error(reason)
        loop(state)
    end
  end

  # =========================================================================
  # Formateadores e Impresión de Pantalla
  # =========================================================================

  defp build_prompt(%State{env: env}) do
    case Environment.nesting_level(env) do
      0 -> "rpn> "
      depth -> "rpn[depth:#{depth}]> "
    end
  end

  defp print_evaluation_result(%State{stack: []}) do
    IO.puts("Pila vacía []")
  end

  defp print_evaluation_result(%State{stack: stack}) do
    formatted_items =
      stack
      |> Enum.reverse()
      |> Enum.map(&format_stack_item/1)
      |> Enum.join(", ")

    [top | _] = stack
    IO.puts("-> #{format_stack_item(top)}  |  Pila: [#{formatted_items}]")
  end

  defp print_stack([]) do
    IO.puts("Pila de evaluación: (vacía)")
  end

  defp print_stack(stack) do
    IO.puts("--- Pila de Evaluación (Cima al inicio) ---")
    stack
    |> Enum.with_index()
    |> Enum.each(fn {item, idx} ->
      IO.puts("  [#{idx}] #{format_stack_item(item)}")
    end)
    IO.puts("--------------------------------------------")
  end

  defp print_variables(env) do
    vars = Environment.variables_with_status(env)

    if Enum.empty?(vars) do
      IO.puts("No hay variables definidas en memoria.")
    else
      IO.puts("=== Variables Activas en Memoria (Tabla de Símbolos) ===")
      IO.puts(
        String.pad_trailing("Nombre", 12) <>
        String.pad_trailing("Tipo", 10) <>
        String.pad_trailing("Valor", 14) <>
        String.pad_trailing("Ámbito", 12) <>
        "Estado"
      )
      IO.puts(String.duplicate("-", 62))

      Enum.each(vars, fn {name, %Value{type: type, raw: raw}, level, status} ->
        scope_label = if level == 0, do: "Global (0)", else: "Local (#{level})"
        type_str = Atom.to_string(type)
        val_str = inspect(raw)
        status_str = if status == :active, do: "[Activa]", else: "[Oculta (Shadowed)]"

        IO.puts(
          String.pad_trailing(name, 12) <>
          String.pad_trailing(type_str, 10) <>
          String.pad_trailing(val_str, 14) <>
          String.pad_trailing(scope_label, 12) <>
          status_str
        )
      end)
      IO.puts(String.duplicate("=", 62))
    end
  end

  defp format_stack_item(%Value{} = val), do: "#{Value.format(val)} (#{val.type})"
  defp format_stack_item({:var_ref, name}), do: "var(#{name})"

  defp print_error(:stack_underflow) do
    IO.puts("[Error de Ejecución] Pila insuficiente (Stack underflow). Se requieren al menos dos operandos para la operación.")
  end

  defp print_error(:division_by_zero) do
    IO.puts("[Error Aritmético] División por cero detectada. La operación no está definida.")
  end

  defp print_error(:no_active_scope) do
    IO.puts("[Error de Ámbito] No hay un bloque local activo para cerrar con 'end'. Ya te encuentras en el ámbito global.")
  end

  defp print_error({:type_error, op, t1, t2}) do
    IO.puts("[Error de Tipos] Operación incompatible '#{op}' entre los tipos #{t1} y #{t2}.")
  end

  defp print_error({:unbound_variable, name}) do
    IO.puts("[Error de Variable] La variable '#{name}' no ha sido declarada en el entorno actual ni en ámbitos padres.")
  end

  defp print_error({:invalid_token, token}) do
    IO.puts("[Error Léxico] Token o comando no reconocido: '#{token}'.")
  end

  defp print_error({:invalid_assignment_target, target}) do
    IO.puts("[Error de Asignación] El lado izquierdo de la asignación '=' debe ser un identificador válido. Recibido: #{inspect(target)}.")
  end

  defp print_error(unknown) do
    IO.puts("[Error Inesperado] #{inspect(unknown)}")
  end

  defp print_welcome_banner do
    IO.puts("""
    ===================================================================
      EVALUADOR RPN EN ELIXIR (Notación Polaca Inversa)
      Asignación #1 - Lenguajes de Programación (FACYT - UC)
      Desarrollado por: Angel Rodriguez y Edgar Martinez
    ===================================================================
    Comandos especiales:
      vars   : Muestra la tabla de símbolos y variables por ámbito
      stack  : Imprime el estado completo de la pila
      begin  : Abre un nuevo ámbito léxico local
      end    : Cierra el ámbito local actual (restaura variables)
      clear  : Vacía la pila de evaluación
      help   : Muestra esta ayuda
      exit   : Salir del programa

    Ejemplos en RPN:
      x 10 =             (asigna 10 a la variable x)
      x 5 + 2 *          (evalúa (x + 5) * 2)
      10 20 <            (evalúa comparación lógica -> true)
      5 true +           (produce un error de tipos controlado)
    ===================================================================
    """)
  end

  defp print_help do
    print_welcome_banner()
  end
end
