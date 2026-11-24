# Evaluador RPN en Elixir (Mini-REPL Postfijo)

**Lenguajes de Programación**  
**Integrantes:**
- Angel Rodriguez C.I: 30.213.906
- Edgar Martinez C.I: 30.222.959

---

## Requisitos de Entorno

- **Erlang/OTP:** 24 o superior.
- **Elixir:** 1.14 o superior.

Verificar instalación con:
```bash
elixir -v
```

---

## Compilación y Ejecución

### 1. Ejecutar el REPL Interactivo

Para iniciar la aplicación directamente mediante `Mix`:
```bash
mix run -e "RpnEvaluator.start()"
```

O desde la consola interactiva `iex`:
```bash
iex -S mix
iex> RpnEvaluator.start()
```

### 2. Compilar como Binario Ejecutable Independiente (Escript)

Para compilar un binario ejecutable portable:
```bash
mix escript.build
./rpn_evaluator
```

### 3. Ejecutar las Pruebas Automatizadas

Para correr la suite de pruebas unitarias:
```bash
mix test
```

---

## Sesión de Prueba de Ejemplo (Entradas en RPN y Salidas Esperadas)

A continuación se muestra una sesión interactiva en la consola REPL:

```text
===================================================================
  EVALUADOR RPN EN ELIXIR (Notación Polaca Inversa)
  Lenguajes de Programación
  Desarrollado por: Angel Rodriguez C.I: 30.213.906 y Edgar Martinez C.I: 30.222.959
===================================================================

rpn> 10 5 +
-> 15 (integer)  |  Pila: [15 (integer)]

rpn> 2 *
-> 30 (integer)  |  Pila: [30 (integer)]

rpn> clear
Pila vaciada.

rpn> x 10 =
-> Asignado x = 10 (integer)  |  Pila: []

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
-> Asignado x = 50 (integer)  |  Pila: []

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
