

void emula():
   memoria = LeArquivoCartucho()
   pc = PosicaoInicialMemoria;

   while (1):
     instrucao = LeMemoria(pc);
     decodificada = DecodificaInstrucao(instrucao);

     switch(decodificada):
       case :

                break;

        default:
               printf("instrução inválida");

     ImprimeLinhaDebug()

def main():
