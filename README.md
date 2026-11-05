# Computação Gráfica

Repositório da disciplina Computação Gráfica, em Lazarus / Free Pascal.

## Sobre o projeto

Um único programa (`CG.lpi`) com uma aba por prática. Os algoritmos desenham pixel a pixel, sem `LineTo`, `Ellipse` ou `FloodFill` da LCL (única exceção: o item f da aba 2). Só usa LCL padrão e units do FPC, então o `.exe` é um arquivo único, sem DLLs.

## Práticas

1. HSL: conversão RGB ↔ HSL
2. Pixels: abrir imagem, cinza, inverter, separar canais
3. Retas: equação geral e paramétrica
4. Bresenham: reta, todos os octantes
5. Círculos: equação, paramétrica e rotação
6. Bresenham círculo: 1ª e 2ª ordem
7. Casinha 3D: transformações com matrizes 4×4
8. Clipping: Cohen-Sutherland e Liang-Barsky
9. Preenchimento: inversão, flood fill e scanline
10. Z-Buffer: remoção de superfícies ocultas

## Estrutura

- `algo/`: algoritmos em units puras, sem LCL
- `f*.pas`: um frame por aba
- `uMain.pas`: janela principal com as abas
- `uAreaDesenho.pas`: área de desenho comum (buffer de pixels)
- `testes/`: testes dos algoritmos, só com FPC

## Como executar

```bash
./build.sh linux     # gera bin/linux/CG
./build.sh win64     # gera bin/win64/CG.exe
testes/rodar.sh      # compila e roda os testes
```

## Requisitos

- Lazarus e FPC (instalados via [fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe), com cross-compiler `x86_64-win64` para gerar o `.exe`)
- Linux: `libgtk2.0-dev` e dependências do Lazarus
