# Teclado 4x4

## 1. Abreviaturas y definiciones
- **FPGA**: Field Programmable Gate Arrays

## 2. Referencias
- [0] David Harris y Sarah Harris. *Digital Design and Computer Architecture. RISC-V Edition.* Morgan Kaufmann, 2022. ISBN: 978-0-12-820064-3

- [1] M. M. Mano and M. D. Ciletti, Digital Design: With an Introduction to the Verilog HDL, VHDL, and SystemVerilog, 5th ed. Boston, MA, USA: Pearson, 2013.

- [2] B. Razavi, Design of Analog CMOS Integrated Circuits, 2nd ed. New York, NY, USA: McGraw-Hill Education, 2016.

## 3. Desarrollo
 - Joan Franco Sandoval 



### 3.0 Descripción general del sistema

El sistema desarrollado consiste en la implementación de un código de Hamming (7,4) utilizando la placa FPGA Tang Nano 9K. Se reciben dos señales de entrada a través de interruptores DIP (Deep Switch). La primera señal es un arreglo de 4 bits que se utiliza para generar el código de Hamming, el cual servirá como referencia para la segunda entrada. Esta segunda entrada es un arreglo de 7 bits que puede contener un error intencional, con el propósito de ser corregido mediante la verificación de paridad de bits.

Una vez identificado el error inducido, se despliega la información correspondiente tanto en el arreglo de LEDs de la FPGA como en un display de siete segmentos. Esta pantalla está controlada mediante transistores BJT y muestra no solo la posición del error detectado en la entrada del segundo interruptor DIP, sino también

### 3.1 Módulo 1

#### 1. Encabezado del módulo
```SystemVerilog
module top (
    input  [3:0] in,              // 4 bits de datos originales
    input  [6:0] dataRaw,         // Código Hamming con error manual (7 switches)
    input        selector,        // 0 = usar encoder | 1 = usar switches con error
    output [6:0] led,             // Muestra los 7 bits corregidos
    output [6:0] segments,        // Muestra el dato corregido en hexadecimal (4 bits)
    output [6:0] segments_error   // Muestra el bit donde se detectó el error
);
```
#### 2. Parámetros

El módulo superior recibe tres parámetros principales:

- in:Es un interruptor DIP . Esta señal será enviada al módulo de Hamming para su codificación.

- dataraw: Es una señal de entrada de 7 bits, también proveniente de unInterruptor DIP . Representa una palabra ya codificada con un error inducido intencionalmente, con el propósito de ser corregida por el sistema.

- selector: Permite elegir qué información se mostrará en la pantalla de siete segmentos y qué datos serán enviados a los LED. Según su valor, "0" selecciona la palabra codificada (in) o "1", selecciona la palabra corregida (proveniente de dataraw).


#### 3. Entradas y salidas:

Entradas:
- in: [3:0] (4 bits) - Datos originales.
- dataRaw: [6:0] (7 bits) - Código Hamming con posible error.
- selector: (1 bit) - Control para seleccionar entre el código Hamming generado o el manual.


Salidas:
- led: [6:0] (7 bits) - Datos corregidos mostrados en LEDs.
- segments: [6:0] (7 bits) - Dato corregido en formato hexadecimal.
- segments_error: [6:0] (7 bits) - Bit donde se detectó el error.
#### 4. Criterios de diseño


#### 4.1 Introducción

Este módulo actúa como el control principal del código, donde se integran los demás módulos y se realizan las llamadas necesarias para asignar las variables correspondientes. Aquí se gestionan tanto las entradas como las salidas, asegurando que cada componente funcione de manera coordinada y eficiente.

#### 4.2 Explicación del Código

- 1. Declaración del Módulo
```SystemVerilog

module top (
    input  [3:0] in,
    input  [6:0] dataRaw,
    input        selector,
    output [6:0] led,
    output [6:0] segments,
    output [6:0] segments_error
);
```
- module top: Define el módulo principal llamado top.
- input: Se declaran las entradas del módulo, especificando el tamaño de cada una.
- output: Se declaran las salidas del módulo, también especificando el tamaño.


- 2. Señales Internas
```SystemVerilog

wire [6:0] dataRaw_from_encoder;
wire [6:0] dataRaw_muxed;
wire [2:0] posError;
wire [6:0] dataCorregido;
wire [3:0] dataCorrecta;
wire [3:0] errorDisplay;

```
wire: Se declaran señales internas que se utilizarán para conectar diferentes módulos y almacenar resultados intermedios. Cada señal tiene un tamaño específico que se ajusta a los datos que manejará.

- 3. Instanciación de Módulos
```SystemVerilog

hamming74 encoder (
    .in(in),
    .ou(dataRaw_from_encoder)
);
```

hamming74 encoder: Se instancia un módulo llamado hamming74, que se encarga de codificar los datos. Se conectan las entradas y salidas mediante la notación de asignación de puertos.

- 4. Multiplexor
```SystemVerilog

assign dataRaw_muxed = selector ? dataRaw : dataRaw_from_encoder;
```

assign: Se utiliza para asignar valores a las señales. En este caso, se utiliza un operador ternario para seleccionar entre dos fuentes de datos basándose en el valor de selector.


- 5. Detección de Errores
```SystemVerilog

hamming_detection detector (
    .dataRaw(dataRaw_muxed),
    .posError(posError)
);
```

hamming_detection detector: Se instancia un módulo que se encarga de detectar errores en el código Hamming. Se conectan las señales de entrada y salida.

- 6. Corrección de Errores
```SystemVerilog

correccion_error corrector (
    .dataRaw(dataRaw_muxed),
    .sindrome(posError),
    .correccion(dataCorregido),
    .dataCorrecta(dataCorrecta)
);
```

correccion_error corrector: Se instancia un módulo que corrige el error detectado. Se conectan las señales necesarias para la corrección y la extracción de datos.

- 7. Visualización en LED
```SystemVerilog

display_7bits_leds display (
    .coregido(dataCorregido),
    .led(led)
);
```
display_7bits_leds display: Se instancia un módulo que se encarga de mostrar los datos corregidos en un conjunto de LEDs. Se conectan las señales de entrada y salida.

- 8. Visualización en 7 Segmentos
```SystemVerilog

sevseg display_hex(
    .bcd(dataCorrecta),
    .segments(segments)
);
```


sevseg display_hex: Se instancia un módulo que convierte los datos en formato BCD a un formato adecuado para un display de 7 segmentos. Se conectan las señales correspondientes.

- 9. Conversión de Posición de Error
```SystemVerilog
assign errorDisplay = (posError == 3'b000) ? 4'd0 : {1'b0, posError};
```

assign: Se utiliza nuevamente para asignar un valor a errorDisplay, que se utiliza para mostrar la posición del error en un formato adecuado.

- 10. Visualización del Error
```SystemVerilog

sevseg display_error(
    .bcd(errorDisplay),
    .segments(segments_error)
);
```
sevseg display_error: Se instancia otro módulo de visualización que muestra la posición del error en un display de 7 segmentos.


#### 5. Testbench

Se define el valor que va a tener selector. Se genera digitalmente la señal recibida, ya sea "in" o "dataRaw" se evalúan los resultados

=== Pruebas top ===
```SystemVerilog
        $display("Caso | selector | in (ref) | dataRaw (error) | Corrected (7-bit) | 7seg (hex)");
        
        // Caso 1: Modo encoder (selector = 0)
        selector = 0;
        in = 4'b1010;
        dataRaw = 7'b0000000; 
        #10;
        $display("  1   |   %b    |   %b   |    %b    |      %b      |  %b", 
                  selector, in, dataRaw, led, segments);
        
        // Caso 2: Modo error (selector = 1)
        selector = 1;
        in = 4'b1010;
        dataRaw = 7'b1000101;
        #10;
        $display("  2   |   %b    |   %b   |    %b    |      %b      |  %b", 
                  selector, in, dataRaw, led, segments);

        // Caso 3: Otro valor en modo error
        selector = 1;
        in = 4'b0110;
        dataRaw = 7'b0110010;
        #10;
        $display("  3   |   %b    |   %b   |    %b    |      %b      |  %b", 
                  selector, in, dataRaw, led, segments);
```
Resultados obtenidos al ejecutar el make test

- ========================== Pruebas del modulo top ================================
- Caso | selector | in (ref) | dataRaw (error) | Corrected (7-bit) | 7seg (hex)
-   1   |   0    |   1010   |    0000000    |      0101101      |  0001000
-   2   |   1    |   1010   |    1000101    |      0101010      |  0000011
-   3   |   1    |   0110   |    0110010    |      1001100      |  0000010

### 3.2 Módulo 2

#### 1. Encabezado del módulo
```SystemVerilog
module keypad_scan #(
    parameter int SCAN_CNT_MAX     = 100_000,
    parameter int DEBOUNCE_CYCLES  = 3
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  columnas,
    output logic [3:0]  filas,
    output logic [1:0]  row,
    output logic [1:0]  col,
    output logic        valid
);

```
#### 2. Parámetros

- SCAN_CNT_MAX (int): número de ciclos de reloj para completar un barrido de las 4 filas.

- DEBOUNCE_CYCLES (int): número de ciclos consecutivos que debe mantenerse estable la entrada de columna para considerar un pulso válido (anti‐rebote).

#### 3. Entradas y salidas
- Entradas:

clk : reloj principal.

rst_n : reset asíncrono activo bajo.

columnas : vector one-hot de 4 bits con el estado de las columnas del teclado (pull-down).

- Salidas:

filas : vector one-hot de 4 bits que activa secuencialmente cada fila.

row : índice (2 bits) de la fila en la que se detectó la tecla.

col : índice (2 bits) de la columna donde se detectó la tecla.

valid : pulso de un ciclo indicando detección de tecla estable tras el debouncing y el escaneo.


#### 4. Criterios de diseño


#### 4.1 Introducción
Este módulo implementa el escaneo de un teclado matricial 4×4, generando señales de fila (filas), identificando la fila y columna activas (row, col) y proporcionando una señal valid cuando se detecta una pulsación consistente (con debounce).

#### 4.2 Explicación del Código


1. Declaración del Módulo
```SystemVerilog
module keypad_scan #(
    parameter int escaneo = 100_000,   
    parameter int ciclos   = 3        
)(
    input  logic        clk,         
    input  logic        rst_n,        
    input  logic [3:0]  columnas,    
    output logic [3:0]  filas,        
    output logic [1:0]  row,          
    output logic [1:0]  col,          
    output logic        valid         
);

```



2. Parámetros Internos
```SystemVerilog

localparam int CNT_WIDTH = $clog2(escaneo);
  
```
- CNT_WIDTH: ancho en bits de scan_counter para contar hasta escaneo–1 sin desbordarse


3. Señales Internas
```SystemVerilog

logic [CNT_WIDTH-1:0] scan_counter;            
logic [1:0]           current_row;            
logic [3:0]           col_sample;              
logic [$clog2(ciclos)-1:0] debounce_cnt;       
logic                 stable;                  

```
- scan_counter avanza cada ciclo de reloj y controla cuándo cambiar de fila y cuándo muestrear la columna.

- current_row cicla entre 0 y 3, seleccionando qué fila está activa físicamente.

- col_sample almacena la lectura previa de columnas para comparar estabilidad.

- debounce_cnt cuenta repeticiones idénticas de columnas para confirmar que no es ruido.

- stable se eleva a 1 cuando columnas permanece sin cambios por ciclos ciclos.]


4. Generación de la Salida de Filas
```SystemVerilog
always_comb begin
    filas = 4'b1 << current_row;
end
 
```

- One-hot Active-High: desplaza un bit ‘1’ hasta la posición de current_row.

- Esto habilita (a nivel físico) la fila correspondiente en el teclado matricial.

5. Lógica de Debounce


```SystemVerilog

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        col_sample   <= 4'd0;
        debounce_cnt <= '0;
        stable       <= 1'b0;
    end else if (columnas == col_sample && columnas != 4'd0) begin
        // La lectura no cambió y no es “ninguna tecla”
        if (debounce_cnt == ciclos - 1) begin
            stable <= 1'b1;          // Columna estable tras suficientes ciclos
        end else begin
            debounce_cnt <= debounce_cnt + 1;
            stable       <= 1'b0;
        end
    end else begin
        // Cambio detectado o ninguna tecla
        col_sample   <= columnas;      // Reinicia la muestra de referencia
        debounce_cnt <= '0;
        stable       <= 1'b0;
    end
end

```
Este bloque de código es el núcleo de la lógica de “debounce” (anti-rebote) para la lectura de las señales de las columnas

- always_ff @(posedge clk or negedge rst_n)

Se ejecuta sincrónicamente en el flanco de subida de clk.

Además, tiene un reset asíncrono activo en bajo (rst_n): si rst_n pasa a 0 en cualquier instante, se fuerza inmediatamente la rama de reset.

- Cuando rst_n == 0 (reset activo):

col_sample se inicializa a 4'd0. Es el registro que guarda la última lectura “de referencia” de las columnas.

debounce_cnt se pone a cero. Este contador lleva la cuenta de ciclos consecutivos durante los cuales la lectura no ha cambiado.

stable se pone a 0. Señala que aún no hemos alcanzado la condición de tecla “estable” tras el rebote.

- Condición

La señal de entrada columnas es igual al valor almacenado en col_sample.

Además, columnas ≠ 4'd0, lo que indica que sí hay alguna tecla presionada (el valor 4'b0000 representa “ninguna columna activa”).


- Sub-casos

Si debounce_cnt == ciclos - 1:
Hemos llegados al último conteo requerido → marcamos stable = 1, indicando que la señal ya está libre de rebotes y podemos considerarla “válida” y estable.

En caso contrario:
Incrementamos debounce_cnt en uno y mantenemos stable = 0 hasta completar el conteo.


- Si la lectura ha variado respecto a col_sample O la lectura es 4'd0 (se soltó la tecla):

- Actualizamos col_sample con el nuevo valor de columnas. Esto reinicia el conteo de estabilidad tomando la última lectura como referencia.

- Reiniciamos debounce_cnt a cero, porque acabamos de detectar un cambio.

- Dejamos stable = 0, pues aún no sabemos si el nuevo valor se mantendrá estable.

- 6. Barrido de Filas y Detección de Tecla
```SystemVerilog


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_counter <= '0;
        current_row  <= 2'd0;
        valid        <= 1'b0;
        row          <= 2'd0;
        col          <= 2'd0;
    end else begin
        


        if (scan_counter == (escaneo >> 1) - 1) begin
            
            if (stable && (col_sample & (col_sample - 1)) == 4'd0) begin
                row   <= current_row;   
                unique case (col_sample)
                    4'b0001: col <= 2'd0;
                    4'b0010: col <= 2'd1;
                    4'b0100: col <= 2'd2;
                    4'b1000: col <= 2'd3;
                    default: col <= 2'd0;
                endcase
                valid <= 1'b1;           
            end else begin
                valid <= 1'b0;           
            end
        end

        
        if (scan_counter == escaneo - 1) begin
            scan_counter <= '0;          
            current_row  <= (current_row == 2'd3)
                            ? 2'd0      
                            : current_row + 1;
        end else begin
            scan_counter <= scan_counter + 1;
            
            if (scan_counter != (escaneo >> 1) - 1)
                valid <= 1'b0;
        end
    end
end

```

- 6.2 Sensibilidad y reset

```SystemVerilog
always_ff @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        scan_counter <= '0;
        current_row  <= 2'd0;
        valid        <= 1'b0;
        row          <= 2'd0;
        col          <= 2'd0;
    end else begin
        …  
    end
end

```

- Sensibilidad:

Se dispara en cada flanco de subida de clk, o en flanco de bajada asíncrono de rst_n.

- Reset asíncrono (!rst_n):

scan_counter se pone a 0: inicia el conteo del ciclo de escaneo.

current_row a 0: empezamos escaneando la fila 0.

valid a 0: ninguna tecla válida aún.

row, col a 0: salidas limpias.

- Este reset garantiza que, al soltar el reset, el escaneo arranca siempre en fila 0 y en un estado “sin tecla”.

- 6.2  Muestreo de columna a mitad de ciclo

```SystemVerilog

if (scan_counter == (escaneo >> 1) - 1) begin
    
    if (stable && (col_sample & (col_sample - 1)) == 4'd0) begin
        row   <= current_row;   
        unique case (col_sample)
            4'b0001: col <= 2'd0;
            4'b0010: col <= 2'd1;
            4'b0100: col <= 2'd2;
            4'b1000: col <= 2'd3;
            default: col <= 2'd0;
        endcase
        valid <= 1'b1;           
    end else begin
        valid <= 1'b0;           
    end
end


```

Dividimos el periodo de escaneo (escaneo ciclos de reloj) en dos. A (escaneo/2)-1 damos tiempo a que la línea de columna se estabilice tras activar la fila.

- Condición de tecla válida:

stable: señal previa (de otro bloque) que indica que la lectura de col_sample lleva N ciclos sin cambiar.

(col_sample & (col_sample - 1)) == 0: test power-of-two que verifica que exactamente un bit esté activo (una única columna presionada).

- Captura de coordenadas:

row <= current_row; guarda la fila actual en la salida row.

El unique case convierte el vector one-hot de columnas (col_sample) en un índice binario col de 0 a 3.

- Generación de valid:

Se produce un pulso a 1 durante un solo ciclo si hay una lectura limpia de tecla. En caso contrario valid queda en 0.

- 6.3  Rotación de filas y conteo de escaneo

```SystemVerilog


if (scan_counter == escaneo - 1) begin
    scan_counter <= '0;         
    current_row  <= (current_row == 2'd3)
                    ? 2'd0       
                    : current_row + 1;
end else begin
    scan_counter <= scan_counter + 1;
    
    if (scan_counter != (escaneo >> 1) - 1)
        valid <= 1'b0;
end



```

- Fin de ciclo de escaneo (scan_counter == escaneo-1):

scan_counter se resetea a 0.

current_row avanza: de la 0 pasa a la 1, …, de la 3 vuelve a la 0.
 Incremento normal (cualquier otro valor de scan_counter):

Se suma 1 al contador.

Importante: fuera de la ventana de muestreo (escaneo/2)-1, la señal valid se fuerza a 0, de modo que sólo haya un pulso en el instante preciso.


#### 5. Testbench





### 3.3 Módulo 3

#### 1. Encabezado del módulo

```SystemVerilog
module keypad_decoder (
    input  logic [1:0] row,
    input  logic [1:0] col,
    output logic [3:0] bcd_value,
    output logic       valid
);

```

#### 2. Parámetros

Este módulo no tiene parámetros configurables solamente se encarga de recibir las señales transmitidas por el módulo de escaneo para codificar el resultado de la evaluación de las columnas y filas

#### 3. Entradas y salidas
- Entradas:
row (2 bits): identifica la fila activa del teclado matricial.

col (2 bits): identifica la columna activa del teclado matricial.

- Salidas:


bcd_value (4 bits): código BCD resultante de la tecla presionada:1–9 para dígitos numéricos, 10 = '*', 0 = tecla '0', 11 = '#'.

- valid (1 bit): indica que la combinación row/col corresponde a una tecla válida (1), o no válida (0).
#### 4. Criterios de diseño

#### 4.1 Introducción

Este módulo convierte la señal de fila/col de un escáner de teclado matricial en un valor BCD de 4 bits y una señal de validez. Permite identificar dígitos del 0 al 9 y las teclas especiales ‘*’ y ‘#’.

#### 4.2 Explicación del Código


1. Declaración del Módulo
```SystemVerilog

module keypad_decoder (
    input  logic [1:0] row,
    input  logic [1:0] col,
    output logic [3:0] bcd_value,
    output logic       valid
);
 
```
- row[1:0]
– Indica la fila activa (one-hot codificada en 2 bits).

- col[1:0]
– Indica la columna detectada (one-hot codificada en 2 bits).

- bcd_value[3:0]
– Salida BCD (0–11) según la tecla presionada.

- valid
– Señal que vale 1 si la combinación row,col corresponde a una tecla definida, 0 si es un estado inválido (niñeo, sin tecla presionada, múltiples filas/columnas simultáneas, etc.).


3. Selección con unique case
```SystemVerilog

unique case ({row, col})
    4'b00_00: bcd_value = 4'd1;   
    4'b00_01: bcd_value = 4'd2;   
    4'b00_10: bcd_value = 4'd3;   

    4'b01_00: bcd_value = 4'd4;   
    4'b01_01: bcd_value = 4'd5;   
    4'b01_10: bcd_value = 4'd6;   

    4'b10_00: bcd_value = 4'd7;   
    4'b10_01: bcd_value = 4'd8;   
    4'b10_10: bcd_value = 4'd9;   

    
    4'b11_00: bcd_value = 4'd10;  
    4'b11_01: bcd_value = 4'd0;   
    4'b11_10: bcd_value = 4'd11;  

    default: begin
        bcd_value = 4'd0;         
        valid     = 1'b0;         
    end
endcase



```
- unique case
– Indica exhaustividad: el sintetizador verifica que no haya solapamiento en condiciones.

- Cada línea mapea exactamente una fila+columna a un dígito:


Fila 0, Columna 1 → tecla '2' \ Fila 1, Columna 2 → tecla '6'\ Fila 2, Columna 1 → tecla '8', etc.



2. Modo Inválido (default)
```SystemVerilog

default: begin
    bcd_value = 4'd0;   // No asumimos un dígito válido
    valid     = 1'b0;   // Señalamos error o ausencia de tecla
end



```

- Se activa si:

- No hay ninguna fila o hay más de una simultánea.

- Columna fuera del rango esperado.

- Estados transitorios entre escaneos.








#### 5. Testbench




### 3.4 Módulo 4

#### 1. Encabezado del módulo
```SystemVerilog
module multiplex_display #(
    parameter int REFRESH_CNT = 1000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  digit0,
    input  logic [3:0]  digit1,
    input  logic [3:0]  digit2,
    output logic [6:0]  segments,
    output logic [2:0]  enable_displays
);
```
#### 2. Parámetros

REFRESH_CNT: número de ciclos de reloj que deben transcurrir antes de cambiar al siguiente dígito. Ajusta la frecuencia de multiplexado.



#### 3. Entradas y salidas

- Entradas:

clk : reloj principal del sistema.

rst_n : reset asíncrono activo bajo.

digit0 : valor BCD (4 bits) del dígito menos significativo.

digit1 : valor BCD (4 bits) del dígito intermedio.

digit2 : valor BCD (4 bits) del dígito más significativo.


- Salidas:

segments : bus de 7 bits que controla los segmentos a–g del display activo.

enable_displays : líneas one-hot de 3 bits para habilitar uno de los tres dígitos.

#### 4. Criterios de diseño

#### 4.1 Introducción

Este módulo implementa el multiplexado de tres displays de 7 segmentos. Utiliza un contador de refresco para ciclar entre los dígitos y un selector para enrutar el valor BCD correspondiente al convertidor de segmentos (sevseg). Con ello, mantiene cada dígito activo durante un breve intervalo

#### 4.2 Explicación del Código

1. Encabezado del Módulo

```SystemVerilog

module multiplex_display #(
    parameter int REFRESH_CNT = 1000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  digit0,
    input  logic [3:0]  digit1,
    input  logic [3:0]  digit2,
    output logic [6:0]  segments,
    output logic [2:0]  enable_displays
);


```

- #( parameter int REFRESH_CNT = 1000 )

Declara un parámetro genérico entero.

Controla cuántos ciclos de clk pasan antes de cambiar al siguiente dígito.

Ajustar este valor regula la “velocidad de escaneo” y afecta al parpadeo percibido.

-  \\ Entrada \\

- clk

Señal de reloj síncrona.

Todos los procesos “always” están sincronizados a su flanco de subida.

- rst_n

Reset asíncrono activo bajo.

Cuando vale 0, inicializa contador y puntero de dígito.

- digit0, digit1, digit2

Cada uno es un nibble BCD (4 bits).

Representan los valores 0–9 que queremos mostrar en cada display.

- \\  Salida  \\

- segments

Bus de 7 bits (a→g) que va al decodificador sevseg.

Determina qué segmentos se encienden para mostrar el número BCD.

- enable_displays

Bus de 3 bits one-hot: un “0” en la posición i activa el display i, los “1” lo desactivan.
 



2. Señales Internas
```SystemVerilog

logic [1:0]  current_display;
logic [16:0] refresh_counter;
logic [3:0]  bcd_value;


```


- current_display[1:0]

Contiene el índice del dígito activo (0, 1 o 2).

Tamaño 2 bits: 00, 01, 10.

- refresh_counter[16:0]

Contador de hasta 2^17 - 1.

Se dimensiona para soportar REFRESH_CNT sin desbordar.

Cuenta ciclos de reloj para temporizar el multiplexado.

- bcd_value[3:0]

Señal intermedia: almacena el nibble BCD del dígito actualmente activo.

Luego lo envía al decodificador de segmentos.



3. Contador de Refresco y Selección de Dígito

```SystemVerilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        refresh_counter <= '0;         // Reinicia el contador
        current_display <= 2'd0;       // Empieza por el primer dígito
    end else if (refresh_counter == REFRESH_CNT) begin
        refresh_counter <= '0;         
        current_display <= 
            (current_display == 2'd2) 
            ? 2'd0                  // Si llegamos al tercer dígito, volvemos al primero
            : current_display + 1; // Si no, avanzamos al siguiente
    end else begin
        refresh_counter <= refresh_counter + 1; // Incrementa mientras no alcance REFRESH_CNT
    end
end

```

- Reset asíncrono

Al llegar rst_n = 0, se fuerza refresh_counter = 0 y current_display = 0.

Garantiza un inicio determinista.

- Contador

En cada flanco de subida de clk, si no estamos reseteados,

Si refresh_counter < REFRESH_CNT, se incrementa.

Cuando iguala a REFRESH_CNT:

Se reinicia (<= '0)

Se cambia current_display (0→1→2→0).

- Puntero de Dígito

Permite ciclar exactamente tres estados (0,1,2) usando la comparación == 2'd2.





4. Enrutamiento de la Salida BCD

```SystemVerilog

always_comb begin
    unique case (current_display)
        2'd0: bcd_value = digit0;
        2'd1: bcd_value = digit1;
        2'd2: bcd_value = digit2;
        default: bcd_value = 4'd0;
    endcase
end


```
- always_comb

Describe lógica combinacional pura: bcd_value se recalcula inmediatamente con cualquier cambio en current_display o digitX.

- unique case

Informa al sintetizador de que current_display cubrirá exhaustivamente 0,1,2.

Mejora detección de errores y evita inferir latch por omisión de casos.

- Flujo

Si current_display == 0, el mux entrega digit0.

Si == 1, entrega digit1.

Si == 2, entrega digit2.

Si un valor inesperado (teóricamente imposible), bcd_value=0. 

5. Generación de las Líneas de Enable


```SystemVerilog

always_comb begin
    unique case (current_display)
        2'd0: enable_displays = 3'b110; 
        2'd1: enable_displays = 3'b101; 
        2'd2: enable_displays = 3'b011; 
        default: enable_displays = 3'b111; 
    endcase
end



```
- One-hot Active-Low

Bit a ‘0’ = transistor de ánodo común conduce → display encendido.

Bits a ‘1’ = display apagado.

- Ciclo

Para current_display = i, todos los bits quedan a ‘1’ excepto el i-ésimo a ‘0’.

6.  Decodificador de Segmentos


```SystemVerilog

always_comb begin
    unique case (current_display)
        2'd0: bcd_value = digit0;
        2'd1: bcd_value = digit1;
        2'd2: bcd_value = digit2;
        default: bcd_value = 4'd0;
    endcase
end


```
- sevseg

Recibe bcd_value[3:0] y produce segments[6:0].

Internamente mapea valores 0–9 a patrones de segmentos (a→g).

Ejemplo: BCD=4 → segmentos b,c,f,g activos, resto apagados.








#### 5. Testbench








### 3.5 Módulo 5


#### 1. Encabezado del módulo
```SystemVerilog

module sevseg(
    input  logic [3:0] bcd,       
    output logic [6:0] segments   
);

```
#### 2. Parámetros

El módulo no tiene parámetros configurables, pero su funcionamiento se basa en la representación de números en un display de 7 segmentos

#### 3. Entradas y salidas:

- Entradas:
bcd: Un vector de 4 bits que representa un número en formato BCD. Este número puede estar en el rango de 0 a 15, aunque solo los valores de 0 a 9 se utilizan comúnmente para mostrar dígitos.

- Salidas:
segments: Un vector de 7 bits que controla los segmentos del display. Cada bit en este vector representa un segmento del display (a-g), donde un 0 enciende el segmento y un 1 lo apaga.

#### 4. Criterios de diseño

#### 4.1 Introducción

El display de 7 segmentos es un dispositivo que puede mostrar números y algunas letras al encender o apagar sus segmentos. Este módulo convierte un número BCD en la configuración de segmentos necesaria para mostrar el número correspondiente en el display.

#### 4.2 Explicación del Código

- 1. Declaración del Módulo

```SystemVerilog

module sevseg(
    input  [3:0] bcd,    
    output reg [6:0] segments 
);
```

module sevseg: Define el módulo.
input [3:0] bcd: Declara una entrada de 4 bits que representa un número en formato BCD. Este número puede ser del 0 al 15, aunque solo los valores del 0 al 9 se utilizan comúnmente para mostrar dígitos en un display de 7 segmentos.
output reg [6:0] segments: Declara una salida de 7 bits que representa el estado de los segmentos del display (a-g). Se utiliza reg porque la salida se asigna dentro de un bloque always.

3. Conversión de BCD a Segmentos


```SystemVerilog
always_comb begin
        case (bcd)
            4'b0000: segments_reg = 7'b0111111; // 0
            4'b0001: segments_reg = 7'b0000110; // 1
            4'b0010: segments_reg = 7'b1011011; // 2
            4'b0011: segments_reg = 7'b1001111; // 3
            4'b0100: segments_reg = 7'b1100110; // 4
            4'b0101: segments_reg = 7'b1101101; // 5
            4'b0110: segments_reg = 7'b1111101; // 6
            4'b0111: segments_reg = 7'b0000111; // 7
            4'b1000: segments_reg = 7'b1111111; // 8
            4'b1001: segments_reg = 7'b1101111; // 9
            4'b1010: segments_reg = 7'b0001000; // A
            4'b1011: segments_reg = 7'b0000011; // b
            4'b1100: segments_reg = 7'b1000110; // C
            4'b1101: segments_reg = 7'b0100001; // d
            4'b1110: segments_reg = 7'b0000110; // E
            4'b1111: segments_reg = 7'b0001110; // F
            default: segments_reg = 7'b0000000; // Apagado tot
        endcase
    end
```
case (bcd): Se utiliza una estructura case para determinar qué segmentos del display deben encenderse según el valor de bcd.
Cada caso corresponde a un valor de bcd y asigna un valor de 7 bits a segments, donde cada bit representa un segmento del display de 7 segmentos (a-g).
Por ejemplo, 7'b1000000 enciende el segmento "a" para mostrar el número 0, mientras que 7'b1111001 enciende los segmentos necesarios para mostrar el número 1.
Los valores de bcd de 10 a 15 (A-F) también están mapeados, lo que permite mostrar letras en el display.
default: Si el valor de bcd no coincide con ninguno de los casos anteriores, se asigna un valor que apaga el display (en este caso, 7'b1100011).



#### 5. Testbench
Descripción y resultados de las pruebas hechas

```SystemVerilog
   bcd_val = 4'hA; 
        #1;
        $display("sevseg: bcd=%h => seg=%b", bcd_val, seg_out);
        bcd_val = 4'h0; 
        #1;
        $display("sevseg: bcd=%h => seg=%b", bcd_val, seg_out);
        bcd_val = 4'h2; 
        #1;
        $display("sevseg: bcd=%h => seg=%b", bcd_val, seg_out);
        bcd_val = 4'h9; 
        #1;
        $display("sevseg: bcd=%h => seg=%b", bcd_val, seg_out);
        
```
Resultados obtenidos al ejecutar el make test

- sevseg: bcd=a => seg=0001000
- sevseg: bcd=0 => seg=1000000
- sevseg: bcd=2 => seg=0100100
- sevseg: bcd=9 => seg=0010000




## 4. Consumo de recursos
Resumen de Recursos Utilizados

### 4.1 Conexiones (Wires)
- Número total de conexiones: 41
- Número total de bits de conexión: 127
- Conexiones públicas: 41
- Bits de conexiones públicas: 127
### 4.2 Memorias
- Número de memorias: 0
- Bits de memoria: 0
### 4.3  Celdas (Cells)
- Total de celdas: 50
- GND: 1
- IBUF (Buffers de entrada): 12
- LUT1 (Look-Up Tables de 1 entrada): 6
- LUT3: 6
- LUT4: 11
- MUX2_LUT5: 6
- MUX2_LUT6: 1
- OBUF (Buffers de salida): 7
### 4.4  Utilización del Dispositivo
- VCC (Voltaje de alimentación): 1/1 (100%)
- SLICE: 23/8640 (0%)
- IOB (Input/Output Blocks): 19/274 (6%)
- ODDR (Double Data Rate Output): 0/274 (0%)
- MUX2_LUT5: 6/4320 (0%)
- MUX2_LUT6: 1/2160 (0%)
- GND: 1/1 (100%)
- GSR (Global Set/Reset): 1/1 (100%)
- OSC (Oscilador): 0/1 (0%)
- rPLL (Phase-Locked Loop): 0/2 (0%)
- Resultados de la Herramienta BC y ABC
- BC RESULTS:
- Celdas LUT: 16
- ABC RESULTS:
- Señales internas: 51
- Señales de entrada: 12
- Señales de salida: 7
### 4.5 Rendimiento y Tiempos de Retardo
- Max delay: Se reporta un retardo máximo de 23.84 ns, lo que es importante para asegurar que el diseño cumpla con los requisitos de temporización.

## 5. Problemas encontrados durante el proyecto

Durante la realización de este proyecto se presentaron diversos errores que afectarán su desarrollo. Uno de los principales inconvenientes surgió al intentar desplegar información en los LEDs de la FPGA. Debido a una interpretación incorrecta de los planos de conexión de la FPGA. Como resultado, la información se muestra de forma invertida, ya que era necesario negar previamente los valores enviados a los LED.

Otro problema significativo fue la incompatibilidad al implementar ciertas herramientas, particularmente con SystemVerilog, a diferencia de Verilog, lo que impidió realizar la síntesis correctamente mediante Yosys.

También se presentan dificultades con el despliegue de información en los displays de siete segmentos, ya que estos no reciben correctamente los datos enviados desde la FPGA.

La integración de los distintos módulos en el módulo superior generó múltiples complicaciones , tanto a nivel de sintaxis como en la lógica utilizada, lo cual requirió una revisión detallada de cada componente.

Finalmente, uno de los errores más críticos estuvo relacionado con la correcta implementación de las constraints , ya que fue necesario especificar adecuadamente el tipo de entrada y resistencias pull-up o pull-down .





