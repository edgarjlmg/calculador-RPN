# Evaluador RPN en Elixir (Mini-REPL Postfijo)

**Universidad de Carabobo**  
**Facultad Experimental de Ciencias y Tecnología (FACYT)**  
**Departamento de Computación - U.A. de Algoritmos, Programación y Lenguajes**  
**Asignatura:** Lenguajes de Programación (CAO604) — Semestre 1-2026  
**Asignación #1**  

### Integrantes del Grupo:
- **Angel Rodríguez**
- **Edgar Martínez**

**Repositorio oficial:** [https://github.com/edgarjlmg/calculador-RPN](https://github.com/edgarjlmg/calculador-RPN)

---

## 1. Descripción del Proyecto

Este proyecto consiste en un **Evaluador Interactivo de Consola (REPL)** basado en **Notación Polaca Inversa (RPN / Postfija)** implementado en **Elixir**, ejecutándose sobre la máquina virtual **BEAM**.

El evaluador procesa expresiones matemáticas y lógicas basadas estrictamente en una **pila de operandos (stack)**, tokenizando las entradas separadas por espacios en blanco. Demuestra de forma práctica los conceptos fundamentales de diseño de lenguajes de programación: **inmutabilidad**, **paso explícito de parámetros por valor con compartición estructural**, **sistema de tipos dinámico y fuerte**, **manejo idiomático de errores mediante tuplas etiquetadas** y **alcance léxico con ocultamiento de variables (scoping y shadowing)**.

---

## 2. Cumplimiento de Requisitos Técnicos

### 2.1. Evaluación en Pila y Manejo Idiomático de Errores
- **Operaciones Aritméticas Básicas:** Suma (`+`), Resta (`-`), Multiplicación (`*`) y División (`/`).
  - Soporta enteros y flotantes, números negativos (`-15`) y prefijos positivos explícitos (`+5`).
- **Operaciones Lógicas y Relacionales:** Menor que (`<`), Mayor que (`>`), Menor o igual (`<=`), Mayor o igual (`>=`), Igualdad (`==`) y Desigualdad (`!=`).
- **Manejo de Errores sin Abortos Abruptos:** Todos los errores se capturan y retornan de forma idiomática mediante tuplas `{:error, reason, state}` usando cláusulas `with` y pattern matching:
  - **División por cero:** `{:error, :division_by_zero}` (ej. `10 0 /`).
  - **Pila insuficiente (Stack underflow):** `{:error, :stack_underflow}` cuando un operador requiere más operandos de los presentes.
  - **Tokens inválidos:** `{:error, {:invalid_token, token}}` para caracteres no reconocidos.
  - **Destino inválido de asignación:** `{:error, {:invalid_assignment_target, target}}` si se intenta asignar a un literal (ej. `10 20 =`).

### 2.2. Sistema de Tipos del Evaluador
- Modelado mediante tipos compuestos nativos (`defstruct` y `@type` en `RpnEvaluator.Types.Value`):
  - Enteros (`:integer`), Flotantes (`:float`) y Booleanos (`:boolean`).
- **Verificación de tipos en tiempo de ejecución:** Si se intenta operar tipos incompatibles (ej. `5 true +`), el evaluador no produce un fallo catastrófico ni coerción implícita indeseada, sino un error controlado:
  ```text
  [Error de Tipos] Operación incompatible 'add' entre los tipos integer y boolean.
  ```

### 2.3. Variables y Paso de Parámetros
- **Declaración y Actualización en Notación Postfija:**
  - `x 10 =` asigna `10` a la variable `x`.
  - `x 5 2 + =` evalúa la subexpresión `5 + 2 = 7` y vincula `7` a `x`.
  - `x 5 + 2 *` recupera el valor de `x` y evalúa `(x + 5) * 2`.
  - `x x 1 + =` reasigna a `x` su valor previo incrementado en 1.
- **Inspección de Memoria (`vars`):** Muestra todas las variables activas en la tabla de símbolos indicando su nombre, tipo, valor, nivel de ámbito y estado de visibilidad (`[Activa]` vs `[Oculta (Shadowed)]`).
- **Paso Explícito de Parámetros e Inmutabilidad:**
  - La pila (`stack`) y el entorno (`env`) se pasan como argumentos explícitos a cada subrutina `(tokens, state)`.
  - Las funciones no mutan estructuras globales; retornan un nuevo estado inmutable `{:ok, %State{stack: new_stack, env: new_env}}`.

### 2.4. Alcance Local (Scoping y Shadowing) con `begin` y `end`
- El comando `begin` abre un nuevo bloque de alcance local temporal (insertando un nuevo mapa en la pila de ámbitos `[ %{} | scopes ]`).
- Las variables declaradas o modificadas dentro del bloque local aplican **shadowing** sobre variables homónimas de ámbitos exteriores.
- El comando `end` destruye el ámbito local activo (`pop_scope`), restaurando intactos los valores de las variables del ámbito exterior.
- Soporta múltiples niveles de anidamiento (`begin ... begin ... end ... end`) e insensibilidad a mayúsculas (`BEGIN`, `END`).

---

## 3. Requisitos de Instalación y Entorno

- **Erlang/OTP:** 24 o superior.
- **Elixir:** 1.14 o superior.
- **Herramienta de compilación:** `Mix` (incluido con Elixir).

Verificar instalación con:
```bash
elixir -v
```

---

## 4. Compilación y Ejecución

### 4.1. Ejecutar el REPL Interactivo

Clonar el repositorio y ubicarse en la raíz del proyecto:
```bash
git clone https://github.com/edgarjlmg/calculador-RPN.git
cd calculador-RPN
```

Para iniciar el REPL interactivo utilizando `Mix`:
```bash
mix run -e "RpnEvaluator.start()"
```
O también dentro de la consola interactiva `iex`:
```bash
iex -S mix
iex> RpnEvaluator.start()
```

### 4.2. Compilar como Binario Ejecutable Independiente (Escript)

Elixir permite empaquetar la aplicación completa en un único archivo ejecutable:
```bash
mix escript.build
./rpn_evaluator
```

### 4.3. Ejecutar la Suite de Pruebas Automatizadas

El proyecto incluye pruebas unitarias exhaustivas con `ExUnit`:
```bash
mix test
```

Salida esperada:
```text
Compiling 5 files (.ex)
.....................
Finished in 0.05 seconds (0.00s async, 0.05s sync)
21 tests, 0 failures
```

---

## 5. Sesión de Prueba de Ejemplo (Entradas en RPN y Salidas Esperadas)

A continuación se muestra una sesión real completa interactuando con el REPL:

```text
===================================================================
  EVALUADOR RPN EN ELIXIR (Notación Polaca Inversa)
  Asignación #1 - Lenguajes de Programación (FACYT - UC)
  Desarrollado por: Angel Rodriguez y Edgar Martinez
===================================================================

rpn> 10 5 +
-> 15 (integer)  |  Pila: [15 (integer)]

rpn> 2 *
-> 30 (integer)  |  Pila: [30 (integer)]

rpn> clear
Pila vaciada.

rpn> x 10 =
-> 10 (integer)  |  Pila: [10 (integer)]

rpn> x 5 + 2 *
-> 30 (integer)  |  Pila: [30 (integer)]

rpn> vars
=== Variables Activas en Memoria (Tabla de Símbolos) ===
Nombre      Tipo      Valor         Ámbito      Estado
--------------------------------------------------------------
x           integer   10            Global (0)  [Activa]
==============================================================

rpn> clear
Pila vaciada.

rpn> begin
rpn[depth:1]> x 50 =
-> 50 (integer)  |  Pila: [50 (integer)]

rpn[depth:1]> x 2 *
-> 100 (integer)  |  Pila: [100 (integer)]

rpn[depth:1]> vars
=== Variables Activas en Memoria (Tabla de Símbolos) ===
Nombre      Tipo      Valor         Ámbito      Estado
--------------------------------------------------------------
x           integer   10            Global (0)  [Oculta (Shadowed)]
x           integer   50            Local (1)   [Activa]
==============================================================

rpn[depth:1]> end
rpn> x
-> 10 (integer)  |  Pila: [10 (integer)]

rpn> vars
=== Variables Activas en Memoria (Tabla de Símbolos) ===
Nombre      Tipo      Valor         Ámbito      Estado
--------------------------------------------------------------
x           integer   10            Global (0)  [Activa]
==============================================================

rpn> clear
Pila vaciada.

rpn> 10 20 <=
-> true (boolean)  |  Pila: [true (boolean)]

rpn> 5 true +
[Error de Tipos] Operación incompatible 'add' entre los tipos integer y boolean.

rpn> 10 0 /
[Error Aritmético] División por cero detectada. La operación no está definida.

rpn> +
[Error de Ejecución] Pila insuficiente (Stack underflow). Se requieren al menos dos operandos para la operación.

rpn> exit
Saliendo del evaluador RPN. ¡Hasta luego!
```

---

## 6. Estructura del Código Fuente

```text
calculador-RPN/
├── mix.exs                     # Configuración del proyecto Mix y dependencias
├── README.md                   # Documentación general y guía de ejecución
├── lib/
│   ├── rpn_evaluator.ex        # Módulo raíz y punto de entrada
│   └── rpn_evaluator/
│       ├── types.ex            # Sistema de tipos (%Value{}, %State{}, errores)
│       ├── environment.ex      # Tabla de símbolos, scoping léxico y shadowing
│       ├── parser.ex           # Tokenizador y clasificador léxico en RPN
│       ├── evaluator.ex        # Motor de evaluación y despacho de operaciones
│       └── cli.ex              # Interfaz de consola interactiva y formateo
└── test/
    ├── test_helper.exs         # Configuración del framework ExUnit
    └── rpn_evaluator_test.exs  # Suite de pruebas unitarias automatizadas
```
