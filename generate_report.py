import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, HRFlowable, PageBreak
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#4B5563"))

        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 755, "Universidad de Carabobo - FACYT | Lenguajes de Programación (CAO604)")
            self.drawRightString(558, 755, "Reporte Técnico: Evaluador RPN en Elixir")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 747, 558, 747)

        # Footer (all pages)
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 45, 558, 45)

        self.drawString(54, 32, "Autores: Angel Rodriguez y Edgar Martinez | Repositorio: github.com/edgarjlmg/calculador-RPN")
        page_text = f"Página {self._pageNumber} de {page_count}"
        self.drawRightString(558, 32, page_text)
        self.restoreState()

def build_pdf(filename="Reporte_Tecnico_RPN_Elixir.pdf"):
    pdf_path = os.path.abspath(filename)
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.HexColor('#0F172A'),
        alignment=1, # Center
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor('#1E3A8A'),
        alignment=1,
        spaceAfter=10
    )

    meta_style = ParagraphStyle(
        'DocMeta',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor('#334155'),
        alignment=1
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=15,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=13,
        textColor=colors.HexColor('#1E3A8A'),
        spaceBefore=8,
        spaceAfter=3,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor('#1F2937'),
        spaceAfter=4.5,
        alignment=4 # Justified
    )

    code_style = ParagraphStyle(
        'CodeSnippet',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=7.2,
        leading=9.5,
        textColor=colors.HexColor('#0F172A'),
        spaceAfter=0
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor('#0C4A6E')
    )

    story = []

    # Title Banner Box
    title_data = [
        [Paragraph("UNIVERSIDAD DE CARABOBO", ParagraphStyle('UC', fontName='Helvetica-Bold', fontSize=10.5, leading=13, alignment=1, textColor=colors.HexColor('#1E3A8A')))],
        [Paragraph("FACULTAD EXPERIMENTAL DE CIENCIAS Y TECNOLOGÍA (FACYT)<br/>DEPARTAMENTO DE COMPUTACIÓN — U.A. DE ALGORITMOS, PROGRAMACIÓN Y LENGUAJES", ParagraphStyle('UCDep', fontName='Helvetica', fontSize=8, leading=10.5, alignment=1, textColor=colors.HexColor('#475569')))],
        [Spacer(1, 2)],
        [Paragraph("REPORTE TÉCNICO: ANÁLISIS DE DISEÑO E IMPLEMENTACIÓN DEL LENGUAJE ELIXIR", title_style)],
        [Paragraph("Componente Práctico: Evaluador Postfijo / Mini-REPL en Notación Polaca Inversa (RPN)", subtitle_style)],
        [Paragraph("<b>Asignatura:</b> Lenguajes de Programación (CAO604) &nbsp;|&nbsp; <b>Semestre:</b> 1-2026<br/><b>Autores:</b> Angel Rodriguez y Edgar Martinez &nbsp;|&nbsp; <b>Profesor:</b> Jesús Pelay<br/><b>Repositorio GitHub:</b> <font color='#1E40AF'><u>https://github.com/edgarjlmg/calculador-RPN</u></font>", meta_style)]
    ]
    title_table = Table(title_data, colWidths=[504])
    title_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#CBD5E1')),
        ('PADDING', (0,0), (-1,-1), 6),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
    ]))
    story.append(title_table)
    story.append(Spacer(1, 8))

    # Helper function for code boxes
    def make_code_box(code_text, label="Extracto de Código (Elixir)"):
        p_code = Paragraph(code_text.strip().replace("\n", "<br/>").replace(" ", "&nbsp;"), code_style)
        header = Paragraph(f"<b>{label}</b>", ParagraphStyle('CodeH', fontName='Helvetica-Bold', fontSize=7.5, textColor=colors.HexColor('#475569')))
        t = Table([[header], [p_code]], colWidths=[504])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#E2E8F0')),
            ('BACKGROUND', (0,1), (-1,1), colors.HexColor('#F8FAFC')),
            ('BOX', (0,0), (-1,-1), 0.75, colors.HexColor('#94A3B8')),
            ('LINEBELOW', (0,0), (-1,0), 0.75, colors.HexColor('#94A3B8')),
            ('PADDING', (0,0), (-1,-1), 4),
            ('TOPPADDING', (0,1), (-1,1), 4),
            ('BOTTOMPADDING', (0,1), (-1,1), 4),
        ]))
        return t

    # Helper function for callouts
    def make_callout(text, prefix="Reflexión de Diseño:"):
        p = Paragraph(f"<b>{prefix}</b> {text}", callout_style)
        t = Table([[p]], colWidths=[504])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F0F9FF')),
            ('BOX', (0,0), (-1,-1), 0.75, colors.HexColor('#BAE6FD')),
            ('LEFTPADDING', (0,0), (-1,-1), 8),
            ('RIGHTPADDING', (0,0), (-1,-1), 8),
            ('TOPPADDING', (0,0), (-1,-1), 4),
            ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ]))
        return t


    # Introducción
    story.append(Paragraph("Resumen Ejecutivo y Contexto del Proyecto", h1_style))
    story.append(Paragraph(
        "El presente informe técnico evalúa las propiedades de diseño, semántica formal y arquitectura de ejecución del lenguaje de programación <b>Elixir</b>, creado por José Valim sobre la máquina virtual <b>BEAM</b> (Erlang VM). El análisis se estructura estrictamente en función de los cuatro ejes teóricos fundamentales de la disciplina de lenguajes: (1) Nombres, vinculación, estructuras de control y alcance; (2) Sistema y chequeo de tipos; (3) Subrutinas, paso de parámetros y gestión de memoria; y (4) Abstracción de datos y polimorfismo. Cada concepto teórico es contrastado y demostrado de manera directa a través del código fuente de un evaluador interactivo en <b>Notación Polaca Inversa (RPN)</b> con manejo de pila, tabla de símbolos con ámbitos léxicos anidados (<i>scoping</i> y <i>shadowing</i>), verificación de tipos en tiempo de ejecución y reporte idiomático de errores.",
        body_style
    ))
    story.append(Spacer(1, 6))

    # =========================================================================
    # SECCIÓN 1
    # =========================================================================
    story.append(Paragraph("1. Nombres, Vinculación (Binding), Estructuras de Control y Reglas de Alcance", h1_style))
    
    story.append(Paragraph("1.1. Nombres, Identificadores y el Operador Match (=)", h2_style))
    story.append(Paragraph(
        "A diferencia de los lenguajes imperativos tradicionales (C, Pascal, Python) donde el operador <code>=</code> denota una <i>asignación destructiva</i> (mutación de una posición de memoria o puntero de variable), en Elixir <code>=</code> es conceptualmente el <b>Operador de Coincidencia de Patrones (Pattern Matching)</b>. Al evaluar <code>patron = expresion</code>, el compilador y la máquina virtual intentan unificar el término de la derecha con la estructura y variables de la izquierda.",
        body_style
    ))
    story.append(Paragraph(
        "Cuando un identificador aparece en el lado izquierdo de una coincidencia no anclada, Elixir realiza una <b>re-vinculación (rebinding)</b> en el ámbito léxico actual. Es fundamental resaltar que esto no muta la estructura de datos original en memoria; simplemente asocia el identificador en la tabla de símbolos del proceso con una nueva dirección o estructura inmutable. En el evaluador RPN desarrollado, la asignación postfija <code>x 10 =</code> emula esta semántica funcional a través de <code>Evaluator.eval_step/2</code>:",
        body_style
    ))

    code_sec1_1 = """# Extracto de lib/rpn_evaluator/evaluator.ex
# Operador de asignación postfija '=' (ej: x 10 =)
defp eval_step({:operator, :assign}, %State{stack: [raw_val, target | rest], env: env} = state) do
  with {:ok, %Value{} = value} <- resolve_operand(raw_val, env),
       {:ok, var_name} <- extract_var_name(target) do
    new_env = Environment.bind(env, var_name, value)
    new_stack = [value | rest]
    {:ok, %State{stack: new_stack, env: new_env}}
  end
end"""
    story.append(make_code_box(code_sec1_1, "Vinculación Funcional de Variables en el Evaluador RPN"))
    story.append(Spacer(1, 6))

    story.append(Paragraph("1.2. Estructuras de Control: Enfoque Expresivo y Optimización de Llamada Terminal", h2_style))
    story.append(Paragraph(
        "En Elixir no existen sentencias (<i>statements</i>) desprovistas de retorno; <b>toda construcción sintáctica es una expresión que evalúa a un valor</b>. Asimismo, el lenguaje prescinde de bucles imperativos primitivos (<code>while</code>, <code>for</code> mutable). La iteración y el flujo de ejecución se fundamentan en dos pilares:",
        body_style
    ))
    story.append(Paragraph(
        "<b>a) Expresiones de Selección y Coincidencia:</b> <code>case</code> (despacho basado en pattern matching), <code>cond</code> (evaluación de la primera rama verdadera, análogo a un <code>cond</code> en Lisp), guardas puras (<code>when</code>) y la construcción monádica <code>with</code>. En nuestro evaluador, <code>with</code> se emplea extensivamente para encadenar operaciones falibles, cortocircuitando al primer <code>{:error, reason}</code> sin anidamientos piramidales de código (*anti-patrón Pyramid of Doom*).<br/>"
        "<b>b) Recursión y Optimización de Llamada Terminal (TCO):</b> En la BEAM, si la última expresión de una función es una invocación a sí misma, el marco de pila actual (*stack frame*) es reutilizado en lugar de asignar uno nuevo. Esto permite que el bucle interactivo de la consola <code>CLI.loop/1</code> y el análisis recursivo de tokens <code>Parser.tokenize_tokens/2</code> operen en espacio de pila O(1) de forma indefinida sin riesgo de desbordamiento (Stack Overflow).",
        body_style
    ))

    code_sec1_2 = """# Extracto de lib/rpn_evaluator/cli.ex: Bucle REPL con TCO
def loop(%State{} = state) do
  prompt = build_prompt(state)
  case IO.gets(prompt) do
    :eof -> IO.puts("\\nSaliendo."); :ok
    line ->
      # Tras evaluar la entrada, loop/1 se llama a sí mismo en posición terminal
      handle_input(String.trim(line), state)
  end
end

defp handle_input(input, %State{} = state) do
  with {:ok, tokens} <- Parser.parse(input),
       {:ok, new_state} <- Evaluator.eval_tokens(tokens, state) do
    print_evaluation_result(new_state)
    loop(new_state) # LLAMADA TERMINAL PURA: marco de pila reutilizado
  else
    {:error, reason, old_state} ->
      print_error(reason)
      loop(old_state) # Retorna al bucle conservando el estado no corrupto
  end
end"""
    story.append(make_code_box(code_sec1_2, "Bucle REPL con Optimización de Llamada Terminal (TCO)"))
    story.append(Spacer(1, 6))

    story.append(Paragraph("1.3. Reglas de Alcance (Lexical Scoping) y Shadowing", h2_style))
    story.append(Paragraph(
        "Elixir implementa un régimen estricto de <b>alcance léxico (Lexical Scoping)</b>. La visibilidad de un identificador queda acotada al bloque sintáctico donde fue introducido (módulos, funciones <code>def</code>, lambdas <code>fn -> end</code>). Las vinculaciones realizadas en el interior de un bloque no se propagan hacia el ámbito circundante exterior.",
        body_style
    ))
    story.append(Paragraph(
        "Para modelar de forma explícita el alcance local y el ocultamiento de variables (<i>shadowing</i>) solicitado en la asignación práctica, se diseñó el módulo <code>Environment</code> como una lista enlazada de mapas <code>[current_local_scope | parent_scopes]</code>. El comando <code>begin</code> apila un nuevo ámbito local en tiempo O(1), mientras que <code>end</code> descarta el ámbito más reciente, garantizando que cualquier variable creada o sobreescrita en el entorno local sea eliminada sin alterar la variable homónima del entorno global:",
        body_style
    ))

    code_sec1_3 = """# Extracto de lib/rpn_evaluator/environment.ex
# Scoping léxico: apertura y cierre de bloques con Shadowing
def push_scope(scopes), do: [%{} | scopes]

def pop_scope([_global_only]), do: {:error, :no_active_scope}
def pop_scope([_local | rest]), do: {:ok, rest}

# Búsqueda con resolución léxica jerárquica (de local a global)
def lookup([], _var_name), do: {:error, :unbound_variable}
def lookup([current_scope | rest], var_name) do
  case Map.fetch(current_scope, var_name) do
    {:ok, %Value{} = value} -> {:ok, value} # Encuentra en ámbito más interno (Shadowing)
    :error -> lookup(rest, var_name)         # Delega recursivamente al ámbito padre
  end
end"""
    story.append(make_code_box(code_sec1_3, "Implementación de Pila de Ámbitos y Resolución Léxica"))
    story.append(Spacer(1, 8))

    # =========================================================================
    # SECCIÓN 2
    # =========================================================================
    story.append(Paragraph("2. Sistema de Tipos de Datos y Mecanismos de Chequeo", h1_style))
    story.append(Paragraph(
        "<b>2.1. Clasificación del Sistema de Tipos: Dinámico y Fuertemente Tipado</b><br/>"
        "Elixir es un lenguaje con un sistema de tipos <b>dinámico</b> y <b>fuertemente tipado (strong & dynamic)</b>:",
        body_style
    ))
    story.append(Paragraph(
        "• <b>Tipado Dinámico:</b> La asociación y comprobación de tipos ocurre en tiempo de ejecución (<i>runtime</i>) en la BEAM. Los tipos están intrínsecamente asociados a los valores y no a las variables o identificadores.<br/>"
        "• <b>Tipado Fuerte:</b> La máquina virtual prohíbe terminantemente la coerción implícita de tipos no compatibles (*implicit type coercion*). En lenguajes de tipado débil como JavaScript, la expresión <code>5 + '10'</code> o <code>5 + true</code> realiza conversiones silenciosas a cadena o entero; en Elixir, cualquier operación incompatible produce un error estricto de tipos (<code>ArithmeticError</code>).<br/>"
        "• <b>Análisis Estático mediante Typespecs y Dialyzer (Success Typings):</b> Aunque el chequeo es dinámico, Elixir soporta especificaciones formales de tipos mediante los atributos de módulo <code>@type</code> y <code>@spec</code>. La herramienta oficial <b>Dialyzer</b> efectúa un análisis estático de discrepancias fundamentado en la teoría de <i>Success Typings</i>, garantizando cero falsos positivos (si emite una advertencia, es certero que ocurrirá un fallo en ejecución).<br/>"
        "• <b>Equivalencia de Tipos:</b> Elixir utiliza equivalencia <i>estructural</i> en mapas y tuplas (dos mapas son equivalentes si sus claves y valores coinciden), y equivalencia <i>nominal/etiquetada</i> en estructuras (<code>defstruct</code>), donde dos structs con idénticos campos pero distinto nombre de módulo no son unificables.",
        body_style
    ))

    story.append(Paragraph("2.2. Modelado de Tipos en el Evaluador RPN y Detección Controlada de Errores", h2_style))
    story.append(Paragraph(
        "En cumplimiento de los requerimientos técnicos de la asignación, los tokens y valores de la pila fueron modelados utilizando tipos compuestos (estructuras y tuplas etiquetadas) con Typespecs formales en <code>RpnEvaluator.Types.Value</code>. El evaluador distingue taxativamente entre números (<code>:integer</code>, <code>:float</code>) y booleanos (<code>:boolean</code>):",
        body_style
    ))

    code_sec2 = """# Extracto de lib/rpn_evaluator/types.ex y evaluator.ex
defmodule RpnEvaluator.Types.Value do
  @enforce_keys [:type, :raw]
  defstruct [:type, :raw]
  @type value_type :: :integer | :float | :boolean
  @type t :: %__MODULE__{type: value_type(), raw: integer() | float() | boolean()}
end

# Chequeo estricto de tipos antes de aplicar operaciones aritméticas (+, -, *, /)
defp check_numeric_types(op, %Value{type: t1}, %Value{type: t2}) do
  if t1 in [:integer, :float] and t2 in [:integer, :float] do
    :ok
  else
    {:error, {:type_error, op, t1, t2}} # Intercepción controlada de error de tipos
  end
end"""
    story.append(make_code_box(code_sec2, "Tipos Algebraicos y Verificación Controlada de Tipos"))
    story.append(Spacer(1, 4))
    story.append(make_callout(
        "Al evaluar la entrada <code>5 true +</code>, la función <code>check_numeric_types/3</code> intercepta que <code>:boolean</code> no satisface el contrato numérico y retorna <code>{:error, {:type_error, :add, :integer, :boolean}}</code>, emitiendo un mensaje descriptivo en consola sin que el proceso REPL aborte abruptamente.",
        "Comportamiento de 5 true +:"
    ))
    story.append(Spacer(1, 8))

    # =========================================================================
    # SECCIÓN 3
    # =========================================================================
    story.append(Paragraph("3. Subrutinas, Mecanismos de Paso de Parámetros y Manejo de Memoria", h1_style))
    story.append(Paragraph(
        "<b>3.1. Subrutinas: Ciudadanos de Primera Clase y Aridad Intrínseca</b><br/>"
        "En Elixir, las subrutinas se estructuran como <b>funciones puras</b> organizadas en módulos (<code>def</code> para funciones públicas, <code>defp</code> para privadas) o funciones anónimas (lambdas). Las funciones son ciudadanos de primera clase (*first-class citizens*), pudiendo ser asignadas a variables, pasadas como argumentos y retornadas por otras subrutinas. Un rasgo identitario de la BEAM es que la <b>aridad</b> (número de argumentos) forma parte integral del identificador de la función; así, <code>lookup/1</code> y <code>lookup/2</code> son subrutinas conceptualmente independientes.",
        body_style
    ))
    story.append(Paragraph(
        "<b>3.2. Paso de Parámetros: Paso por Valor con Compartición Estructural (Structural Sharing)</b><br/>"
        "Semánticamente, Elixir opera bajo un régimen estricto de <b>paso por valor (Pass-by-Value)</b>: una función jamás puede mutar la variable del llamador (*caller*). No existen apuntadores directos a memoria ni modificadores de referencia mutables (como <code>ref</code> o <code>&mut</code>).",
        body_style
    ))
    story.append(Paragraph(
        "No obstante, a nivel de implementación en la máquina virtual BEAM, este paso por valor no incurre en el costo prohibitivo de copiar recursivamente las estructuras de datos (*deep copy*). Dado que todos los datos son matemáticamente inmutables, la BEAM pasa referencias internas de solo lectura protegidas. Las modificaciones generan nuevas estructuras que reutilizan los nodos no modificados de la estructura preexistente (**Estructuras de Datos Persistentes y Compartición Estructural**). En nuestro evaluador, la pila y la tabla de símbolos se transfieren explícitamente a las subrutinas de evaluación, retornando un nuevo registro de estado inmutable <code>%State{}</code>:",
        body_style
    ))

    code_sec3 = """# Extracto de lib/rpn_evaluator/evaluator.ex
# Paso explícito de la pila y el entorno a las subrutinas de evaluación
@spec eval_tokens([Parser.token()], State.t()) :: {:ok, State.t()} | {:error, any(), State.t()}
def eval_tokens([], %State{stack: stack, env: env} = state) do
  # Retorna el estado consolidado sin efectos secundarios globales
  case resolve_stack(stack, env, []) do
    {:ok, resolved_stack} -> {:ok, %State{state | stack: resolved_stack}}
    {:error, reason} -> {:error, reason, state}
  end
end

def eval_tokens([token | rest], %State{} = state) do
  case eval_step(token, state) do
    {:ok, %State{} = next_state} -> eval_tokens(rest, next_state) # Estado transformado
    {:error, reason} -> {:error, reason, state}
  end
end"""
    story.append(make_code_box(code_sec3, "Paso Explícito de Estado Inmutable en Evaluator.eval_tokens/2"))
    story.append(Spacer(1, 6))

    story.append(Paragraph("3.3. Arquitectura de Memoria de la BEAM y Recolección de Basura (GC)", h2_style))
    story.append(Paragraph(
        "La gestión de memoria en Elixir y Erlang difiere radicalmente de los entornos basados en un montículo global único (*single shared heap*) como la JVM o Node.js/V8:",
        body_style
    ))
    story.append(Paragraph(
        "• <b>Montículos Aislados por Proceso (Shared-Nothing Architecture):</b> Cada proceso liviano de la BEAM posee su propio espacio de memoria completamente independiente, compuesto por una pila (*call stack*) y un montículo privado (*private heap*). No existen bloqueos globales de sincronización (locks/mutexes) para la asignación de memoria ordinaria.<br/>"
        "• <b>Recolección de Basura Generacional e Independiente:</b> Cada proceso ejecuta su propio recolector de basura (GC) generacional de copia (*copying GC*) de dos generaciones (<i>Young</i> y <i>Old generation</i>). Debido a que el GC se ejecuta de forma localizada y por micro-pausas que involucran únicamente al proceso en cuestión, <b>no existen pausas globales del sistema completo (*Stop-The-World*)</b>, garantizando latencias predecibles en sistemas concurrentes.<br/>"
        "• <b>Montículo Compartido para Binarios Grandes (Refc Binaries):</b> Para evitar la duplicación de secuencias voluminosas (como cadenas o binarios mayores a 64 bytes), la BEAM asigna estos bloques en un montículo compartido global administrado mediante conteo de referencias atómico (*Reference Counting*).",
        body_style
    ))
    story.append(Spacer(1, 8))

    # =========================================================================
    # SECCIÓN 4
    # =========================================================================
    story.append(Paragraph("4. Abstracción de Datos y Conceptos de POO (vs. Programación Funcional)", h1_style))
    story.append(Paragraph(
        "<b>4.1. Filosofía de Elixir: Datos Puros y Módulos vs. Clases y Objetos</b><br/>"
        "Elixir no es un lenguaje orientado a objetos en el sentido clásico de la taxonomía de Simula/Smalltalk/Java: no existen clases, no existe herencia de implementación y no existe el encapsulamiento de estado mutable dentro de instancias de objetos. En su lugar, Elixir consagra el paradigma de <b>Programación Funcional Orientada a Datos</b>:",
        body_style
    ))
    story.append(Paragraph(
        "• <b>Abstracción y Encapsulamiento:</b> Se logra mediante la combinación de <b>Módulos (<code>defmodule</code>)</b> que agrupan funciones puras y <b>Estructuras (<code>defstruct</code>)</b> que modelan la forma canónica de los datos con validaciones en compilación. La ocultación de detalles internos se implementa mediante funciones privadas (<code>defp</code>) y tipos opacos (<code>@opaque</code>).<br/>"
        "• <b>Polimorfismo Ad-Hoc mediante Protocolos (defprotocol / defimpl):</b> En lugar de jerarquías de herencia, Elixir ofrece polimorfismo paramétrico y ad-hoc a través de <b>Protocolos</b>, el equivalente idiomático a los <i>Traits</i> de Rust o las <i>Typeclasses</i> de Haskell. Un protocolo define una interfaz contractual que puede implementarse para cualquier tipo de dato (incluso tipos primitivos) sin modificar la definición original del tipo (*Principio de Abierto/Cerrado*).<br/>"
        "• <b>Comportamientos (@behaviour):</b> Equivalente a las interfaces abstractas de Java o Go, permiten definir un conjunto formal de funciones (callbacks) que un módulo receptor está obligado a suministrar.",
        body_style
    ))

    code_sec4 = """# Equivalente idiomático de Polimorfismo mediante Protocolos en Elixir:
defprotocol RpnPrintable do
  @doc "Contrato polimórfico para visualización de elementos"
  def format_value(data)
end

defimpl RpnPrintable, for: RpnEvaluator.Types.Value do
  def format_value(%{type: :boolean, raw: b}), do: "bool(#{b})"
  def format_value(%{type: :integer, raw: i}), do: "int(#{i})"
  def format_value(%{type: :float, raw: f}), do: "float(#{f})"
end"""
    story.append(make_code_box(code_sec4, "Polimorfismo Ad-Hoc mediante Protocolos (Traits Funcionales)"))
    story.append(Spacer(1, 6))

    story.append(Paragraph("4.2. Composición vs. Herencia: El Operador Pipe (|>)", h2_style))
    story.append(Paragraph(
        "Elixir previene los problemas inherentes a la herencia profunda (como el problema de la clase base frágil o la ambigüedad en diamante) adoptando la <b>composición modular de funciones</b> a través del operador de tubería (<i>Pipe Operator</i> <code>|></code>). Este operador inyecta el resultado de la expresión anterior como el primer argumento de la función subsecuente. Este patrón se evidencia con total claridad en <code>Parser.parse/1</code> y <code>Environment.all_variables/1</code>:",
        body_style
    ))

    code_sec4_2 = """# Extracto de lib/rpn_evaluator/environment.ex
def all_variables(scopes) when is_list(scopes) do
  depth_total = length(scopes) - 1

  scopes
  |> Enum.with_index()
  |> Enum.flat_map(fn {scope, idx} ->
    level = depth_total - idx
    Enum.map(scope, fn {name, val} -> {name, val, level} end)
  end)
  |> Enum.sort_by(fn {name, _val, level} -> {level, name} end)
end"""
    story.append(make_code_box(code_sec4_2, "Composición Funcional Pura mediante el Operador Pipe (|>)"))
    story.append(Spacer(1, 8))

    # =========================================================================
    # SECCIÓN 5: CONCLUSIONES Y TABLA COMPARATIVA
    # =========================================================================
    story.append(Paragraph("5. Tabla Comparativa de Conceptos de Lenguaje y Conclusiones", h1_style))
    story.append(Paragraph(
        "A modo de síntesis global, la siguiente matriz técnica sistematiza cómo se manifiestan los cuatro ejes teóricos analizados en el diseño de Elixir y cómo fueron abordados en el desarrollo del Evaluador RPN:",
        body_style
    ))

    table_data = [
        [
            Paragraph("<b>Eje Teórico</b>", ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=7.5, textColor=colors.white)),
            Paragraph("<b>Enfoque de Elixir (BEAM)</b>", ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=7.5, textColor=colors.white)),
            Paragraph("<b>Manifestación en el Evaluador RPN</b>", ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=7.5, textColor=colors.white))
        ],
        [
            Paragraph("<b>1. Nombres y Vinculación</b>", ParagraphStyle('TD1', fontName='Helvetica-Bold', fontSize=7)),
            Paragraph("Pattern Matching (operador =), inmutabilidad de datos y re-vinculación en ámbito léxico.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7)),
            Paragraph("Asignación postfija <code>x 10 =</code> vincula en tabla de símbolos retornando nuevo mapa inmutable.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph("<b>2. Flujo y Alcance</b>", ParagraphStyle('TD1', fontName='Helvetica-Bold', fontSize=7)),
            Paragraph("Expresiones puras, TCO para recursión, ámbito léxico estricto sin filtración de variables.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7)),
            Paragraph("Comandos <code>begin</code> / <code>end</code> con pila de scopes; TCO en el bucle REPL interactivo.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph("<b>3. Sistema de Tipos</b>", ParagraphStyle('TD1', fontName='Helvetica-Bold', fontSize=7)),
            Paragraph("Dinámico y fuertemente tipado; tipos algebraicos, tipospecs y análisis Dialyzer.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7)),
            Paragraph("Struct <code>%Value{}</code> distingue Int, Float y Bool; errores controlados (ej: <code>5 true +</code>).", ParagraphStyle('TD', fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph("<b>4. Subrutinas y Memoria</b>", ParagraphStyle('TD1', fontName='Helvetica-Bold', fontSize=7)),
            Paragraph("Paso por valor inmutable con compartición estructural; montículos aislados y GC por proceso.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7)),
            Paragraph("Pila y entorno pasados explícitamente a <code>eval_tokens/2</code>; cero mutación de estado global.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7))
        ],
        [
            Paragraph("<b>5. Abstracción y POO</b>", ParagraphStyle('TD1', fontName='Helvetica-Bold', fontSize=7)),
            Paragraph("Módulos + Structs, Protocolos (polimorfismo ad-hoc), Composición con Pipe (<code>|></code>).", ParagraphStyle('TD', fontName='Helvetica', fontSize=7)),
            Paragraph("Separación estricta de datos y funciones; canalización modular de transformaciones de estado.", ParagraphStyle('TD', fontName='Helvetica', fontSize=7))
        ]
    ]

    summary_table = Table(table_data, colWidths=[100, 200, 204])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1E3A8A')),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.HexColor('#FFFFFF'), colors.HexColor('#F8FAFC')]),
        ('PADDING', (0,0), (-1,-1), 3.5),
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 6))


    story.append(Paragraph("Conclusión Final", h2_style))
    story.append(Paragraph(
        "El desarrollo del Evaluador RPN en Elixir demostró de manera tangible las ventajas conceptuales y prácticas del paradigma funcional sobre la arquitectura de la BEAM. La conjunción de inmutabilidad estricta, compartición estructural de memoria, paso explícito de parámetros y resolución de ámbitos léxicos mediante estructuras de datos persistentes permite construir sistemas altamente confiables, donde los estados intermedios no sufren corrupciones colaterales ante errores de ejecución. El manejo idiomático de errores mediante tuplas etiquetadas y la verificación dinámica y fuerte de tipos garantizan un sistema robusto, verificable y extensible.",
        body_style
    ))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Reporte PDF generado exitosamente en: {pdf_path}")
    return pdf_path

if __name__ == '__main__':
    build_pdf()
