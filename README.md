# Computação Gráfica — Práticas (Lazarus / Free Pascal)

Um único projeto Lazarus (`CG.lpi`) com uma aba por prática. Só LCL padrão e units do FPC:
o `.exe` é um arquivo único, sem DLLs, que roda em qualquer Windows 64 bits.

## 1. Instalar o ambiente (Pop!_OS / Ubuntu)

O FPC/Lazarus do apt não traz o cross-compiler para Windows, então usa-se o **fpcupdeluxe**.

```bash
sudo apt install -y build-essential libgtk2.0-dev libgdk-pixbuf2.0-dev libpango1.0-dev \
  libcairo2-dev libatk1.0-dev libx11-dev libgl1-mesa-dev wine64
mkdir -p ~/fpcupdeluxe && cd ~/fpcupdeluxe
curl -L -o fpcupdeluxe https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/download/v2.4.0k/fpcupdeluxe-x86_64-linux-gtk2
chmod +x fpcupdeluxe && ./fpcupdeluxe
```

Na janela do fpcupdeluxe:

1. Aba **Setup+**: FPC = `stable`, Lazarus = `stable`, diretório `~/fpcupdeluxe/`.
   Deixe **vazios** os campos *FPC options* / *Lazarus options* (escrever `stable` ali quebra o build).
   Se o build travar em `fpmake` (0% de CPU), desligue o build paralelo (make jobs) e tente de novo.
2. **Install/update FPC+Lazarus**.
3. Aba **Cross**: CPU `x86_64`, OS `win64`, **Install cross-compiler**.

## 2. Compilar

Usa o `lazbuild` do fpcupdeluxe (não o do sistema):

```bash
./build.sh linux     # = lazbuild --bm=Linux CG.lpi      -> bin/linux/CG
./build.sh win64     # = lazbuild --bm=Windows64 CG.lpi  -> bin/win64/CG.exe
```

Build modes do `CG.lpi`:

| Modo | Alvo | Widgetset | Observações |
|---|---|---|---|
| `Linux` | x86_64-linux | gtk2 | só para testar no desenvolvimento |
| `Windows64` | x86_64-win64 | win32 | sem info de debug, "Win32 gui application" (sem console) |

## 3. Testes dos algoritmos

```bash
testes/rodar.sh      # compila e roda testes/TestesCG.lpr (console, só FPC)
```

Cobre: HSL, Bresenham de reta (8 direções) e de circunferência, Liang-Barsky e Cohen-Sutherland,
matrizes, preenchimento (flood fill 4 × 8, inversão, e scanline igual à inversão em polígono côncavo) e Z-buffer.

## 4. Testar o .exe no Linux com Wine

```bash
wine bin/win64/CG.exe
```

Abra cada aba e compare com `bin/linux/CG`.

## 5. Estrutura

- `algo/` — algoritmos em units puras (sem LCL): `uCores`, `uLinhas`, `uCirculos`, `uMatriz`,
  `uClipping`, `uPreenchimento`, `uZBuffer`. Recebem um `TPlotProc` ou um buffer próprio.
- `uAreaDesenho.pas` — área de desenho comum (buffer de pixels + `TImage`, botão Limpar, rótulo x,y).
  Nada de `LineTo`/`Ellipse`/`FloodFill`: só plotar pixel (exceção: aba 2, item f).
- `f*.pas` — um `TFrame` por aba; `uMain.pas` — `TPageControl` com as abas.

## 6. O que cada aba faz

1. **HSL** (Aula 03) — RGB ↔ HSL pelo algoritmo inteiro da Microsoft (HLSMAX=240, RGBMAX=255) + amostra de cor.
2. **Pixels** (Aula 04) — abrir imagem (bmp/png/jpg), cinza (ponderado ou média), inverter, separar R/G/B,
   ler pixel sob o mouse (x,y e R,G,B), clique desenha ponto, retas com `MoveTo/LineTo` (único uso permitido).
3. **Retas** (Aula 05/05A) — equação geral e paramétrica (passo 1/max ou fixo 0,01, que deixa buracos); botão estrela.
4. **Bresenham** (Aula 06) — todos os octantes; comentários ligam o código a `d`, `dE`, `dNE`.
5. **Círculos** (Aula 07) — `sqrt`, paramétrica (passo ajustável), rotações de 1 grau; opção de simetria de 8. Clique+arraste: centro e raio.
6. **Bresenham círculo** (Aula 08) — 2ª ordem (`dE`, `dSE`) e 1ª ordem para comparar.
7. **Casinha 3D** (Aula 11/12/12A) — matrizes 4×4 com vetor linha; escala local/global, translação,
   rotação (origem/centro), shearing (matriz digitada), EXECUTA cumulativo, Reset. Projeção ortogonal, y para cima.
8. **Clipping** (Aula 15) — 2 cliques = janela; arrastar = reta (com prévia); Cohen-Sutherland ou Liang-Barsky; parte descartada em cinza.
9. **Preenchimento** (Aula 16) — inversão de cores com bounding box e passo a passo; flood fill com pilha explícita
   (vizinhança 4/8); scanline com lista ordenada de interseções (modo 3); "Grade de teste" em zoom 20×20 mostra a
   vizinhança 8 vazando pelas diagonais.
10. **Z-Buffer** (Aula 17) — 5 objetos (liga/desliga cada um), rotação em torno da origem, zoom, menor z vence.

O rodapé de cada aba mostra x,y do mouse e um texto de status (pixels plotados nas abas 3–6, centro do objeto na
casinha, resultado do recorte no clipping).

## 7. Observações

- **HSL:** o HSL de 240 níveis perde precisão: algumas cores voltam com erro de até ~2 níveis
  (ex.: `(64,128,255)` → `(64,126,255)`). É limite do algoritmo da Microsoft; o teste de ida e volta usa cores 0/128/255.
- **Clipping:** o caso do enunciado dá `(35,38; 10)–(80; 51,43)` (o exato é 51,4286; o enunciado trunca para 51,42).
- **Z-Buffer:** o z do objeto 1 (`x²+y`, até 940) é multiplicado por 0,1 para não sair da tela ao rotacionar;
  a escala da janela usa o raio máximo dos objetos, que não muda com a rotação.
- **Y para cima:** o clipping e a casinha usam a transformação janela/porta de visão (Aula 13) e invertem y no fim.
- `CG --captura prefixo` salva cada aba em `prefixoN.bmp` e fecha (uso interno, para conferir sem clicar).
