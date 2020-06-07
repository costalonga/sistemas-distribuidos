Para executar os testes, basta rodar os scripts lua server1, server2 e server3.lua, passando o caminho para o arquivo de interface.
Todos os arquivos devem estar no mesmo diretorio do arquivo "luarpc.lua", para serem executados.

O arquivo client.lua contem os testes, para executá-lo basta passar o caminho do arquivo de interface e um inteiro de 0 a 3 para escolher o tipo de teste:
  0 - Server 1 faz chamada simples como no 2o trabalho
  1 - Server 1 faz duas chamadas RPC para si mesmo
  2 - Server 1 faz chamada para Server 2
  3 - Server 1 faz chamada RPC para Server 2 que faz chamada RPC para Server 3
