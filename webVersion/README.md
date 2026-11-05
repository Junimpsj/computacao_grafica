# Versão Web

Mesmas 10 práticas da versão Lazarus, no navegador, com visual de formulário Lazarus no Windows XP.

## Sobre o projeto

HTML + CSS + JavaScript puro, sem framework, sem build e sem dependências. Os algoritmos em `js/algo.js` são portados 1:1 das units de `algo/` (mesma matemática, mesmos nomes) e desenham pixel a pixel num buffer próprio. Única exceção: o item f da aba 2, que usa linha pronta do canvas (o `LineTo` do Lazarus).

## Estrutura

- `index.html`: janela e abas
- `css/style.css`: visual XP
- `js/algo.js`: algoritmos (sem DOM, roda também no Node)
- `js/ui.js`: área de desenho e controles
- `js/abas.js`: uma função por aba
- `js/main.js`: troca de abas (`index.html#7` abre a aba 7)
- `teste.js`: testes dos algoritmos

## Como executar

Abra `index.html` no navegador (duplo clique, não precisa de servidor).

```bash
node teste.js     # testes dos algoritmos
```

## Requisitos

- Navegador moderno
- Node.js (só para os testes)
