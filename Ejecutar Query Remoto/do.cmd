ECHO                  ---***--- INICIO %1 ---***--- >ResultadoParcial.log
osql -S%1 -Usa -Psa -i"Query.sql" -n -t120 >>ResultadoParcial.log
ECHO                  ---***--- FIN %1 ---***--- >>ResultadoParcial.log
copy ResultadoTotal.log + ResultadoParcial.log ResultadoTotal.log
