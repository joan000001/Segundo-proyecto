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

La función principal de este código es detectar las pulsaciones de un teclado matricial 4×4. Para ello, en cada ciclo de reloj la FPGA envía un pulso de escaneo por una de las filas y lee las columnas en busca de un retorno. Así, al saber qué fila emitió el pulso y qué columna recibió la señal, se identifica exactamente la tecla presionada.

A continuación, un decodificador traduce esa combinación fila-columna en un valor BCD (0–9) o en códigos para teclas especiales. Esos datos quedan almacenados en registros internos y, cuando se requiera, se vuelven a decodificar para mostrarse en un display de siete segmentos de tres dígitos: cada dígito se habilita secuencialmente mediante su señal enable_display y se actualizan los segmentos según el valor almacenado.
### 3.1 Módulo 1

#### 1. Encabezado del módulo
```SystemVerilog
module top (
    input  logic        clk,
    input  logic [3:0]  columnas,
    output logic [3:0]  filas,
    output logic [6:0]  segments,
    output logic [2:0]  enable_displays
);

```
#### 2. Parámetros

El módulo top ofrece cuatro puertos físicos de conexión a la FPGA, organizados en dos bloques funcionales: el teclado matricial y el display de siete segmentos de tres dígitos.

Teclado matricial
Las señales del teclado se distribuyen en filas y columnas. Las filas funcionan como líneas de barrido (salidas) y las columnas como líneas de detección (entradas). Al activar secuencialmente cada fila y leer la respuesta en las columnas, el sistema determina qué tecla ha sido pulsada.

Display de siete segmentos
Cada uno de los siete segmentos está conectado, a través de resistencias, a los LEDs que conforman el dígito. El display de tres dígitos se controla mediante tres señales de habilitación (enable_display), una por cada dígito; al activar la correspondiente, se encienden los segmentos con el valor BCD deseado.

#### 3. Entradas y salidas:

- Entradas:

clk : reloj principal.

columnas (4 bits): estado de las columnas del teclado matricial (one-hot, pull-down).

- Salidas:
filas (4 bits) : líneas one-hot de las filas para el escaneo.

segments (7 bits) : bus de segmentos para el display activo.

enable_displays (3 bits) : líneas one-hot para habilitar uno de los tres dígitos.

#### 4. Criterios de diseño


#### 4.1 Introducción

El módulo top integra el escáner de teclado (keypad_scan), el decodificador BCD (keypad_decoder), la máquina de estados de captura de dígitos y el multiplexor de displays (multiplex_display). Permite:

- 1.Escanear la matriz 4×4 y validar pulsaciones.

- 2.Traducir filas/columnas a un valor BCD y señal de validez.

- 3.Capturar hasta tres dígitos, avanzando con ‘#’ y reseteando con ‘*’.

- 4.Mostrar los dígitos en tres displays de 7 segmentos de forma multiplexada.
#### 4.2 Explicación del Código

1. Definición de puertos
```SystemVerilog

module top (
    input  logic        clk,               // Reloj principal
    input  logic [3:0]  columnas,          // Líneas de columna del keypad
    output logic [3:0]  filas,             // Salida de filas para escaneo
    output logic [6:0]  segments,          // Bus de segmentos 7-seg
    output logic [2:0]  enable_displays    // Enable one-hot de cada dígito
);
          

```
- clk: sincroniza todo el sistema.

- columnas: entradas de la matriz 4×4, cada bit corresponde a una columna.

- filas: salidas one-hot que activan una de las 4 filas del teclado.

- segments y enable_displays: controlan los tres dígitos del display multiplexado.


2. Señales internas y detección de “*” y “#”
```SystemVerilog

logic [1:0] row, col;        
logic       raw_valid, dec_valid;
logic [3:0] decoded;
logic [1:0] target_digit;
logic [3:0] digits [2:0];
logic       key_hash_d;

wire key_star = raw_valid && dec_valid && (decoded == 4'd10);
wire key_hash = raw_valid && dec_valid && (decoded == 4'd11);

```
- row,col: fila y columna detectadas (0–3).

- raw_valid viene de la etapa de escaneo; dec_valid de la etapa de decodificación.

- decoded: valor BCD de 0–9, 10="*", 11="#"

- key_star, key_hash: pulsos válidos de “*” y “#” respectivamente (combinacional).

3.  Escaneo y debounce: keypad_scan
```SystemVerilog

keypad_scan #(
    .SCAN_CNT_MAX    (100_000),
    .DEBOUNCE_CYCLES (3)
) u_scan (
    .clk      (clk),
    .rst_n    (1'b1),
    .columnas (columnas),
    .filas    (filas),
    .row      (row),
    .col      (col),
    .valid    (raw_valid)
);



```

Rotea filas cada 100 000 ciclos, hace debounce en 3 muestras. A la mitad de cada periodo de escaneo genera raw_valid junto con row,col.

- 4. Decodificación de coordenadas a BCD: keypad_decoder
```SystemVerilog

keypad_decoder u_dec (
    .row       (row),
    .col       (col),
    .bcd_value (decoded),
    .valid     (dec_valid)
);

```

Convierte la pareja (row,col) en un código 0–11 y marca con dec_valid cuando hay un valor fiable.




- 5. Máquina de captura de dígitos y cambio de dígito activo
```SystemVerilog
always_ff @(posedge clk) begin
    
    key_hash_d <= key_hash;

    if (key_star) begin
        
        digits[0]    <= 4'd0;
        digits[1]    <= 4'd0;
        digits[2]    <= 4'd0;
        target_digit <= 2'd0;
    end else begin
        
        if (key_hash && !key_hash_d)
            target_digit <= (target_digit == 2) ? 2'd0 : target_digit + 1;

        
        if (raw_valid && dec_valid && (decoded < 4'd10))
            digits[target_digit] <= decoded;
    end
end


```
- ‘*’ resetea todos los dígitos y sitúa el cursor en el primer dígito (target_digit = 0).

- ‘#’ en su flanco ascendente hace target_digit = target_digit + 1 (circular de 0→1→2→0).

- Cuando llega un 0–9 válido y no es “*” ni “#”, se escribe en digits[target_digit].

- 6. Mostrar en los 7-segmentos: multiplex_display
```SystemVerilog

multiplex_display #(
    .REFRESH_CNT (100_000)
) u_display (
    .clk            (clk),
    .rst_n          (1'b1),
    .digit0         (digits[0]),
    .digit1         (digits[1]),
    .digit2         (digits[2]),
    .segments       (segments),
    .enable_displays(enable_displays)
);

```

Cada 100 000 ciclos refresca uno a uno los tres dígitos, leyendo digits[0..2] y activando el ánodo correspondiente.




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
        
        if (debounce_cnt == ciclos - 1) begin
            stable <= 1'b1;          
        end else begin
            debounce_cnt <= debounce_cnt + 1;
            stable       <= 1'b0;
        end
    end else begin
        
        col_sample   <= columnas;      
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

6. Barrido de Filas y Detección de Tecla
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

6. 1 Sensibilidad y reset

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

6. 2 Muestreo de columna a mitad de ciclo

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

6. 3  Rotación de filas y conteo de escaneo

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



```SystemVerilog

        
  
    
    for (int i = 0; i < 4; i++) begin
      for (int j = 0; j < 4; j++) begin
        row = i;
        col = j;
        #10;
        $display("%0t   %b   %b  |     %0d      %b",
                 $time, row, col, bcd_value, valid);
      end
    end
        
```
Resultados obtenidos al ejecutar el make test

- Time   row col | bcd_value valid

- 10000   00   00  |     1      1
- 20000   00   01  |     2      1
- 30000   00   10  |     3      1
- 40000   00   11  |     0      0
- 50000   01   00  |     4      1
- 60000   01   01  |     5      1
- 70000   01   10  |     6      1
- 80000   01   11  |     0      0
- 90000   10   00  |     7      1
- 100000   10   01  |     8      1
- 110000   10   10  |     9      1
- 120000   10   11  |     0      0
- 130000   11   00  |     10      1
- 140000   11   01  |     0      1
- 150000   11   10  |     11      1
- 160000   11   11  |     0      0





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

 \\ Entrada \\

- clk

Señal de reloj síncrona.

Todos los procesos “always” están sincronizados a su flanco de subida.

- rst_n

Reset asíncrono activo bajo.

Cuando vale 0, inicializa contador y puntero de dígito.

- digit0, digit1, digit2

Cada uno es un nibble BCD (4 bits).

Representan los valores 0–9 que queremos mostrar en cada display.

\\  Salida  \\

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

```SystemVerilog

        
        rst_n  = 0;
        digit0 = 4'd1;
        digit1 = 4'd2;
        digit2 = 4'd3;
        #20;

        
        rst_n = 1;
        #200;

        
        digit0 = 4'd4; digit1 = 4'd5; digit2 = 4'd6;
        #200;
        digit0 = 4'd7; digit1 = 4'd8; digit2 = 4'd9;
        #200;
        digit0 = 4'd0; digit1 = 4'd1; digit2 = 4'd2;
        #200;
        
```
Resultados obtenidos al ejecutar el make test

- Time    Display  Segments  Enable
-      0  \ 0      \ 1111001   \ 110
- 125000  \ 1      \ 0100100   \ 101
- 220000  \ 1      \ 0010010   \ 101
- 235000  \ 2      \ 0000010   \ 011
- 345000  \ 0      \ 0011001   \ 110
- 420000  \ 0      \ 1111000   \ 110
- 455000  \ 1      \ 0000000   \ 101
- 565000  \ 2      \ 0010000   \ 011
- 620000  \ 2      \ 0100100   \ 011
- 675000  \ 0      \ 1000000   \ 110
- 785000  \ 1      \ 1111001   \ 101







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


El diseño sintetizado ocupa cerca del 2 % de las celdas lógicas (181 de 8 640 SLICEs) en el GW1NR-9C.

Se utilizan el 6 % de las entradas/salidas (19 de 274 IOBs).

No emplea memorias ni bloques DSP.

El objetivo de frecuencia era 27 MHz; el diseño soporta hasta 142.9 MHz (u_display.clk) y 133 MHz (u_scan.clk), con amplio margen de timing.

2. Consumo de Lógica
- Total de celdas: 233 (incluye LUTs, flip-flops, constantes y buffers).

- LUTs:

- 5 LUT1, 25 LUT2, 30 LUT3, 34 LUT4, 10 MUX2_LUT5

- Elementos aritméticos: 38 ALUs

- Flip-flops: 6 DFF, 20 DFFE, 21 DFFR, 23 DFFRE

- El uso de LUTs y FFs es muy bajo, dejando abundante espacio para futuras ampliaciones.

3. Entradas/Salidas y Señales
- Wires: 119 señales (379 bits)

- Buffers: 5 IBUF, 14 OBUF

- Constantes del fabric: 1 VCC, 1 GND, 1 GSR

- Uso de IOB: 19 de 274 (6 %)

- Se dispone de la mayoría de E/S libres para conectar más periféricos.

4. Memoria y DSP
- Memorias: 0 bloques RAM utilizados

- RAMW: 0/270

- Bloques DSP (rPLL, OSC): no empleados



5. Rendimiento y Timing
- Frecuencia objetivo: 27 MHz

-  Máxima frecuencia lograda:

- u_display.clk → 142.92 MHz

- u_scan.clk → 133.00 MHz

- 5.1 Ruta Crítica (posedge → posedge)
- Lógica: 3.5 ns

- Enrutamiento: 10.6 ns

- Total: ~14.1 ns (equivale a ~71 MHz teórico, pero la herramienta estima 142.9 MHz)



6. Colocación y Enrutamiento
- Wirelength inicial: 5 961 → final: ~356

- Tiempo de colocación: 0.11 s

- Tiempo de enrutamiento: 2.08 s

- Simulated annealing redujo el “timing cost” de 70 a 36.



## 5. Problemas encontrados durante el proyecto

Uno de los primeros errores detectados estuvo en la lógica de antirrebote. Al intentar apoyarnos en herramientas externas no se logró integrar correctamente el filtrado de pulsaciones, por lo que acabamos implementando soluciones alternativas que no cumplen con los requisitos de estabilidad ni latencia esperados.

Otro fallo crítico fue la ausencia del módulo de suma. Éste debía:

1. Capturar y almacenar los dígitos leídos por el teclado matricial.

2. Convertirlos de BCD a binario.

3. Realizar la operación aritmética.

4. Enviar el resultado al display de siete segmentos.

Sin ese bloque, no se pudo procesar ni mostrar la suma de los valores introducidos.

Por último, el propio escaneo del teclado presentó problemas recurrentes:

El contador de escaneo y el reloj no estaban sincronizados, lo que generaba saltos o lecturas fantasma.

A veces era necesario mantener la tecla pulsada durante muchos ciclos para que el sistema la detectara.

Estas deficiencias obligaron a revisar a fondo tanto la parametrización del temporizador de escaneo como la lógica de muestreo de columnas.




