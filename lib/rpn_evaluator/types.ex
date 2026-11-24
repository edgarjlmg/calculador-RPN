defmodule RpnEvaluator.Types do
  @moduledoc """
  Definición formal del sistema de tipos para el Evaluador RPN.
  Modela valores en la pila, errores de dominio y el estado inmutable del sistema.
  Cumple con los requisitos de tipos algebraicos y tagged unions idiomáticas en Elixir.
  """

  defmodule Value do
    @moduledoc """
    Representa un valor fuertemente tipado en la pila de evaluación.
    Distingue explícitamente entre enteros (:integer), flotantes (:float) y booleanos (:boolean).
    """
    @enforce_keys [:type, :raw]
    defstruct [:type, :raw]

    @type value_type :: :integer | :float | :boolean
    @type t :: %__MODULE__{
      type: value_type(),
      raw: integer() | float() | boolean()
    }

    @doc "Constructor para valores enteros."
    @spec new_integer(integer()) :: t()
    def new_integer(val) when is_integer(val), do: %__MODULE__{type: :integer, raw: val}

    @doc "Constructor para valores de punto flotante."
    @spec new_float(float()) :: t()
    def new_float(val) when is_float(val), do: %__MODULE__{type: :float, raw: val}

    @doc "Constructor para valores booleanos."
    @spec new_boolean(boolean()) :: t()
    def new_boolean(val) when is_boolean(val), do: %__MODULE__{type: :boolean, raw: val}

    @doc "Determina si el valor es numérico (entero o flotante)."
    @spec numeric?(t()) :: boolean()
    def numeric?(%__MODULE__{type: type}), do: type in [:integer, :float]

    @doc "Formatea el valor para visualización en consola."
    @spec format(t()) :: String.t()
    def format(%__MODULE__{type: :boolean, raw: true}), do: "true"
    def format(%__MODULE__{type: :boolean, raw: false}), do: "false"
    def format(%__MODULE__{type: :float, raw: raw}), do: :erlang.float_to_binary(raw, [:compact, decimals: 6])
    def format(%__MODULE__{type: :integer, raw: raw}), do: Integer.to_string(raw)
  end

  defmodule State do
    @moduledoc """
    Representa el estado completo del evaluador:
    - `stack`: Pila de operandos (Valores concretos o referencias a identificadores pendientes).
    - `env`: Lista de mapas que representan los ámbitos léxicos activos (Scoping y Shadowing).
    """
    @enforce_keys [:stack, :env]
    defstruct [:stack, :env]

    @type stack_item :: Value.t() | {:var_ref, String.t()}
    @type t :: %__MODULE__{
      stack: list(stack_item()),
      env: list(map())
    }

    @doc "Crea un nuevo estado inicial con pila vacía y ámbito global."
    @spec new() :: t()
    def new do
      %__MODULE__{
        stack: [],
        env: [%{}]
      }
    end
  end

  # Definición de tipos de errores idiomáticos
  @type eval_error ::
    :stack_underflow
    | :division_by_zero
    | :no_active_scope
    | {:type_error, atom(), atom(), atom()}
    | {:unbound_variable, String.t()}
    | {:invalid_token, String.t()}
    | {:invalid_assignment_target, any()}
end
