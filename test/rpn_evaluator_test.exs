defmodule RpnEvaluatorTest do
  use ExUnit.Case, async: true
  alias RpnEvaluator.{Evaluator, Parser, Environment}
  alias RpnEvaluator.Types.{Value, State}

  describe "1. Evaluación en Pila y Operaciones Aritméticas" do
    test "suma y resta de enteros" do
      {:ok, tokens} = Parser.parse("15 7 + 4 -")
      {:ok, %State{stack: [top | _]}} = Evaluator.eval_tokens(tokens, State.new())
      assert top == Value.new_integer(18)
    end

    test "multiplicación y división con enteros" do
      {:ok, tokens} = Parser.parse("10 4 * 8 /")
      {:ok, %State{stack: [top | _]}} = Evaluator.eval_tokens(tokens, State.new())
      assert top == Value.new_integer(5)
    end

    test "operaciones con flotantes" do
      {:ok, tokens} = Parser.parse("5.5 2.5 + 2 *")
      {:ok, %State{stack: [top | _]}} = Evaluator.eval_tokens(tokens, State.new())
      assert top == Value.new_float(16.0)
    end

    test "error de división por cero con enteros" do
      {:ok, tokens} = Parser.parse("10 0 /")
      assert {:error, :division_by_zero, _state} = Evaluator.eval_tokens(tokens, State.new())
    end

    test "error de división por cero con flotantes" do
      {:ok, tokens} = Parser.parse("10.0 0.0 /")
      assert {:error, :division_by_zero, _state} = Evaluator.eval_tokens(tokens, State.new())
    end

    test "error de pila insuficiente (stack underflow)" do
      {:ok, tokens} = Parser.parse("5 +")
      assert {:error, :stack_underflow, _state} = Evaluator.eval_tokens(tokens, State.new())
    end

    test "error de token inválido" do
      assert {:error, {:invalid_token, "@#$"}} = Parser.parse("5 @#$ +")
    end
  end

  describe "2. Sistema de Tipos y Operaciones Lógicas" do
    test "comparación relacional menor y mayor que" do
      {:ok, tokens1} = Parser.parse("10 20 <")
      {:ok, %State{stack: [top1]}} = Evaluator.eval_tokens(tokens1, State.new())
      assert top1 == Value.new_boolean(true)

      {:ok, tokens2} = Parser.parse("10 20 >")
      {:ok, %State{stack: [top2]}} = Evaluator.eval_tokens(tokens2, State.new())
      assert top2 == Value.new_boolean(false)
    end

    test "comparación de igualdad y desigualdad" do
      {:ok, tokens1} = Parser.parse("42 42 ==")
      {:ok, %State{stack: [top1]}} = Evaluator.eval_tokens(tokens1, State.new())
      assert top1 == Value.new_boolean(true)

      {:ok, tokens2} = Parser.parse("true false !=")
      {:ok, %State{stack: [top2]}} = Evaluator.eval_tokens(tokens2, State.new())
      assert top2 == Value.new_boolean(true)
    end

    test "error de tipos en operaciones aritméticas con booleanos (5 true +)" do
      {:ok, tokens} = Parser.parse("5 true +")
      assert {:error, {:type_error, :add, :integer, :boolean}, _state} =
               Evaluator.eval_tokens(tokens, State.new())
    end

    test "error de tipos en comparación relacional entre booleano y número" do
      {:ok, tokens} = Parser.parse("true 10 <")
      assert {:error, {:type_error, :lt, :boolean, :integer}, _state} =
               Evaluator.eval_tokens(tokens, State.new())
    end
  end

  describe "3. Variables y Paso de Parámetros" do
    test "declaración y asignación de variables (x 10 =)" do
      {:ok, tokens} = Parser.parse("x 10 =")
      {:ok, %State{env: env}} = Evaluator.eval_tokens(tokens, State.new())
      assert {:ok, %Value{raw: 10, type: :integer}} = Environment.lookup(env, "x")
    end

    test "evaluación y asignación compuesta (x 5 2 + =)" do
      {:ok, tokens} = Parser.parse("x 5 2 + =")
      {:ok, %State{env: env}} = Evaluator.eval_tokens(tokens, State.new())
      assert {:ok, %Value{raw: 7, type: :integer}} = Environment.lookup(env, "x")
    end

    test "uso de variable en expresión posterior (x 5 + 2 *)" do
      # 1. Asignar x = 10
      {:ok, t1} = Parser.parse("x 10 =")
      {:ok, state1} = Evaluator.eval_tokens(t1, State.new())

      # 2. Evaluar x 5 + 2 * -> (10 + 5) * 2 = 30
      {:ok, t2} = Parser.parse("x 5 + 2 *")
      {:ok, %State{stack: [result | _]}} = Evaluator.eval_tokens(t2, state1)
      assert result == Value.new_integer(30)
    end

    test "error al consultar variable no declarada" do
      {:ok, tokens} = Parser.parse("variable_inexistente 5 +")
      assert {:error, {:unbound_variable, "variable_inexistente"}, _state} =
               Evaluator.eval_tokens(tokens, State.new())
    end
  end

  describe "4. Alcance Local (Scoping y Shadowing con begin / end)" do
    test "shadowing de variables dentro de un bloque temporal" do
      # Paso 1: Variable global x = 10
      {:ok, t1} = Parser.parse("x 10 =")
      {:ok, s1} = Evaluator.eval_tokens(t1, State.new())
      assert {:ok, %Value{raw: 10}} = Environment.lookup(s1.env, "x")

      # Paso 2: Abrir bloque 'begin' y sobreescribir x = 20
      {:ok, t2} = Parser.parse("begin x 20 =")
      {:ok, s2} = Evaluator.eval_tokens(t2, s1)
      assert {:ok, %Value{raw: 20}} = Environment.lookup(s2.env, "x")
      assert Environment.nesting_level(s2.env) == 1

      # Paso 3: Cerrar bloque 'end' -> x debe restaurar su valor global 10
      {:ok, t3} = Parser.parse("end")
      {:ok, s3} = Evaluator.eval_tokens(t3, s2)
      assert {:ok, %Value{raw: 10}} = Environment.lookup(s3.env, "x")
      assert Environment.nesting_level(s3.env) == 0
    end

    test "variables locales creadas en un bloque se descartan al salir" do
      {:ok, t1} = Parser.parse("begin y 99 =")
      {:ok, s1} = Evaluator.eval_tokens(t1, State.new())
      assert {:ok, %Value{raw: 99}} = Environment.lookup(s1.env, "y")

      {:ok, t2} = Parser.parse("end")
      {:ok, s2} = Evaluator.eval_tokens(t2, s1)
      assert {:error, :unbound_variable} = Environment.lookup(s2.env, "y")
    end

    test "error al intentar cerrar el ámbito global con end" do
      {:ok, tokens} = Parser.parse("end")
      assert {:error, :no_active_scope, _state} = Evaluator.eval_tokens(tokens, State.new())
    end

    test "anidamiento múltiple de bloques (profundidad 2)" do
      {:ok, t1} = Parser.parse("val 1 = begin val 2 = begin val 3 =")
      {:ok, s1} = Evaluator.eval_tokens(t1, State.new())
      assert {:ok, %Value{raw: 3}} = Environment.lookup(s1.env, "val")
      assert Environment.nesting_level(s1.env) == 2

      {:ok, t2} = Parser.parse("end")
      {:ok, s2} = Evaluator.eval_tokens(t2, s1)
      assert {:ok, %Value{raw: 2}} = Environment.lookup(s2.env, "val")
      assert Environment.nesting_level(s2.env) == 1

      {:ok, t3} = Parser.parse("end")
      {:ok, s3} = Evaluator.eval_tokens(t3, s2)
      assert {:ok, %Value{raw: 1}} = Environment.lookup(s3.env, "val")
      assert Environment.nesting_level(s3.env) == 0
    end
  end
end
