# MC861/MC871: Projeto em Computação II / III

## Grupo:
* Edson Duarte RA:145892 
* Lucas Henrique Waki RA:147021 
* Matheus Mendes Araujo RA:156737 
* Juliana Yuki Okubo RA:177320


## Emulador

O trabalho consiste em programar um emulador de NES em Python. 

### Desenvolvimento

#### Instalação

*NOTA*: Instalando deste modo, você pode desenvolver normalmente sem precisar
reinstalar o pacote!

```bash
cd mc861-nes
git pull
pip install -e emulator
pynesemu path/to/nes/rom
```

#### Testes

```bash
cd mc861-nes

# script de testes proposto para avaliação
make test

# executa um test individual
emulator/tools/test.sh test_name # e.g. 000

# executa todos os testes em emulator/tst
emulator/tools/test-all.sh

# gera um relatório com cobertura de código
tox -c emulator
```

### Links relacionados:
- [Py3NES](https://www.github.com/PyAndy/Py3NES)
- [nes-py](https://www.github.com/Kautenja/nes-py)


## Jogo

Durante o primeiro mês, desenvolvemos um jogo baseado em
[Columns](https://www.youtube.com/watch?v=0p5yzwNA_Ls) /
[Magic Jewelry](https://www.youtube.com/watch?v=s5scYfg9HHA)
para NES (Nintendo Entertainment System) em Assembly / MOS6502.

Para executar diretamente no Mednafen:
```bash
bash run.sh
```

A geração da rom do jogo pode ser feita através de:
```bash
cd game
asm6f rom.asm rom.nes
```
