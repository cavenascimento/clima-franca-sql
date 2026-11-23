# Clima da França: banco de dados meteorológico com interface SQL interativa

Projeto de banco de dados construído a partir de dados abertos reais da **Météo-France**, o serviço meteorológico nacional da França. Os arquivos CSV originais foram tratados e normalizados em um modelo relacional de 5 tabelas, com scripts para **PostgreSQL, MySQL e SQL Server**, um banco pronto em **SQLite** e uma **interface web** que executa SQL diretamente no navegador.

**Autor:** Cauã Venseguerra Nascimento

**Interface online:** _(cole aqui o link da página publicada ou do GitHub Pages)_

---

## Sumário

1. [O que o projeto entrega](#1-o-que-o-projeto-entrega)
2. [Estrutura do repositório](#2-estrutura-do-repositório)
3. [Dados de origem](#3-dados-de-origem)
4. [Modelo de dados](#4-modelo-de-dados)
5. [Tratamento aplicado aos dados](#5-tratamento-aplicado-aos-dados)
6. [Como executar](#6-como-executar)
7. [Consultas de exemplo](#7-consultas-de-exemplo)
8. [A interface web](#8-a-interface-web)
9. [Limitações conhecidas](#9-limitações-conhecidas)
10. [Tecnologias](#10-tecnologias)
11. [Fonte, licença e créditos](#11-fonte-licença-e-créditos)

---

## 1. O que o projeto entrega

- **Modelagem relacional** de dados climatológicos: 5 tabelas, chaves primárias e estrangeiras, índices e um catálogo de 40 indicadores.
- **Scripts SQL completos** para PostgreSQL, MySQL e SQL Server (criação das tabelas, carga dos CSVs, conversão de tipos e conferência final).
- **Banco SQLite pronto** (`db/meteo_franca.db`), para consultar sem instalar servidor.
- **Interface web** com painel, mapa, editor de consultas SQL, análises e diagrama ER.

Volume dos dados após o tratamento:

| Tabela | Linhas |
|---|---|
| `posto` | 1.574 |
| `estacao_synop` | 190 |
| `indicador` | 40 |
| `normal` | 331.420 |
| `recorde` | 70.839 |

## 2. Estrutura do repositório

```
clima-franca/
├── README.md
├── sql/
│   ├── meteo_postgresql.sql
│   ├── meteo_mysql.sql
│   └── meteo_sqlserver.sql
├── db/
│   └── meteo_franca.db
├── data/
│   ├── fr_meteofrance_normale_climatologique.csv
│   ├── fr_meteofrance_station_climatologique.csv
│   └── fr_meteofrance_station_synop.csv
└── web/
    └── clima_franca.html
```

| Pasta | Conteúdo |
|---|---|
| `sql/` | Um script por sistema de banco de dados. |
| `db/` | Banco SQLite já populado. |
| `data/` | CSVs originais da Météo-France (necessários para rodar os scripts de servidor). |
| `web/` | Página única e autocontida, com o banco embutido. |

## 3. Dados de origem

Três arquivos CSV da Météo-France:

| Arquivo | Conteúdo |
|---|---|
| `fr_meteofrance_normale_climatologique.csv` | Normais climatológicas de 1991 a 2020 e recordes absolutos, em formato longo: uma linha por posto, indicador e período (mês de 01 a 12 ou valor anual). |
| `fr_meteofrance_station_climatologique.csv` | Cadastro dos postos com ficha climatológica: número de oito dígitos, nome, departamento, coordenadas, altitude e data de edição da ficha. |
| `fr_meteofrance_station_synop.csv` | Cadastro das estações SYNOP: indicativo OMM, indicativo WIGOS, nome, coordenadas, altitude, data de abertura e intervalo de anos de observação. |

Os indicadores cobrem temperatura, precipitação, vento, insolação, radiação, evapotranspiração, graus-dias e contagens de dias acima ou abaixo de limiares.

## 4. Modelo de dados

```
indicador (1) ──< normal >── (1) posto
indicador (1) ──< recorde >── (1) posto

estacao_synop  (cadastro independente)
```

### `indicador`
Catálogo dos 40 indicadores.

| Coluna | Descrição |
|---|---|
| `id` | Chave primária. |
| `codigo` | Código original da Météo-France (único). |
| `descricao_pt` | Descrição em português. |
| `descricao_fr` | Descrição original em francês. |
| `unidade` | Unidade de medida. |
| `categoria` | temperatura, precipitacao, vento, insolacao_radiacao, evapotranspiracao, graus_dias ou fenomenos. |
| `tipo` | `media`, `contagem_dias` ou `recorde`. |

### `posto`
Postos climatológicos: `numero_poste` (PK), `nome`, `departamento`, `latitude`, `longitude`, `altitude`, `data_edicao`.

### `estacao_synop`
Estações SYNOP: `indicativo_omm` (PK), `indicativo_wigos`, `nome`, `latitude`, `longitude`, `altitude`, `data_abertura`, `ano_inicio_obs`, `ano_fim_obs`.

### `normal`
Valores normais de 1991–2020 (médias e contagens de dias).

| Coluna | Descrição |
|---|---|
| `numero_poste` | FK para `posto`. |
| `indicador_id` | FK para `indicador`. |
| `periodo` | `0` = valor anual; `1` a `12` = mês. |
| `valor` | Valor do indicador. |
| `ref_inicio`, `ref_fim` | Anos inicial e final do período de referência. |

Chave primária composta: `(numero_poste, indicador_id, periodo)`.

### `recorde`
Recordes absolutos por posto, indicador e período.

| Coluna | Descrição |
|---|---|
| `numero_poste` | FK para `posto`. |
| `indicador_id` | FK para `indicador`. |
| `periodo` | `0` = anual; `1` a `12` = mês. |
| `valor` | Valor do recorde. |
| `dia`, `ano` | Dia e ano em que o recorde ocorreu (o dia pode ser nulo nos registros anuais). |
| `serie_inicio`, `serie_fim` | Datas de início e fim da série em que o recorde foi medido. |

Chave primária composta: `(numero_poste, indicador_id, periodo)`.

## 5. Tratamento aplicado aos dados

1. **Normalização em 5 tabelas.** O CSV de normais é uma tabela única em formato longo; ela foi separada em `normal`, `recorde` e `indicador`, e os cadastros ficaram em `posto` e `estacao_synop`.
2. **Recordes separados das médias.** No CSV original ficavam na mesma tabela, diferenciados apenas por colunas que só os recordes preenchem (dia, ano e datas da série).
3. **Período anual como `0`.** No CSV o valor anual vinha como o texto `annee`; agora é o inteiro `0`, e os meses são `1` a `12`.
4. **Indicador duplicado unificado.** O indicador de dias com chuva de 50 mm ou mais aparecia com dois textos de descrição, diferentes apenas em espaços. Foi unificado em um só.
5. **Catálogo enriquecido.** Cada indicador recebeu descrição em português, categoria e tipo.
6. **Chaves e índices.** Chaves primárias compostas, chaves estrangeiras e índices por indicador e período, para acelerar as consultas.
7. **Sem vínculos inventados.** Os cadastros de postos e de estações SYNOP não têm uma chave em comum nos arquivos. Por isso `estacao_synop` é uma tabela independente.

## 6. Como executar

Todos os comandos abaixo partem da raiz do repositório. Os scripts de servidor carregam os CSVs de `data/`.

### Opção A: SQLite (mais rápida, sem instalar servidor)

```bash
sqlite3 db/meteo_franca.db
```

```sql
SELECT COUNT(*) FROM normal;   -- esperado: 331420
```

Também funciona com qualquer cliente gráfico de SQLite (DB Browser for SQLite, DBeaver etc.).

### Opção B: PostgreSQL (13 ou superior)

Crie um banco vazio, entre na pasta `data/` e rode o script. O comando `\copy` procura os CSVs na pasta atual.

```bash
createdb meteo_db
cd data
psql -d meteo_db -f ../sql/meteo_postgresql.sql
```

O script cria o schema `meteo` e as tabelas dentro dele.

### Opção C: MySQL (8 ou superior)

A carga usa `LOAD DATA LOCAL INFILE`, que precisa estar habilitado.

```bash
cd data
mysql --local-infile=1 -u SEU_USUARIO -p
```

Dentro do cliente MySQL:

```sql
SET GLOBAL local_infile = 1;
SOURCE ../sql/meteo_mysql.sql;
```

O script cria o banco `meteo`.

### Opção D: SQL Server (2017 ou superior)

O `BULK INSERT` lê os arquivos a partir do **servidor**, então os CSVs precisam estar em um caminho que ele acesse. O script usa `C:\dados\` como pasta padrão.

1. Copie os três CSVs para `C:\dados\` (ou ajuste o caminho dentro do script).
2. Abra `sql/meteo_sqlserver.sql` no SSMS ou no Azure Data Studio e execute.

O script cria o banco `meteo`.

### Conferência após a carga (todas as opções)

O final de cada script de servidor já executa a conferência. Os valores esperados são:

| postos | synop | normais | recordes |
|---|---|---|---|
| 1574 | 190 | 331420 | 70839 |

Se os números forem diferentes, confira o caminho dos CSVs e a codificação UTF-8 dos arquivos.

## 7. Consultas de exemplo

Os exemplos abaixo usam sintaxe compatível com SQLite e PostgreSQL. Em SQL Server, troque `LIMIT n` por `SELECT TOP n`. Em PostgreSQL, prefixe as tabelas com `meteo.` ou rode `SET search_path = meteo;` antes.

**Dez postos com a maior temperatura já registrada**

```sql
SELECT p.nome, p.altitude, r.valor AS tmax_c, r.dia, r.ano
FROM recorde r
JOIN posto p USING (numero_poste)
WHERE r.indicador_id = (SELECT id FROM indicador WHERE codigo = 'temperature_maximale_absolue')
  AND r.periodo = 0
ORDER BY r.valor DESC
LIMIT 10;
```

**Chuva média por mês**

```sql
SELECT n.periodo AS mes, ROUND(AVG(n.valor), 1) AS chuva_media_mm, COUNT(*) AS postos
FROM normal n
JOIN indicador i ON i.id = n.indicador_id
WHERE i.codigo = 'precipitation_hauteur_moyenne'
  AND n.periodo BETWEEN 1 AND 12
GROUP BY n.periodo
ORDER BY n.periodo;
```

**Postos mais ensolarados (horas de sol por ano)**

```sql
SELECT p.nome, p.altitude, ROUND(n.valor) AS horas_sol_ano
FROM normal n
JOIN posto p USING (numero_poste)
JOIN indicador i ON i.id = n.indicador_id
WHERE i.codigo = 'duree_insolation_moyenne' AND n.periodo = 0
ORDER BY n.valor DESC
LIMIT 10;
```

**Catálogo de indicadores**

```sql
SELECT id, codigo, descricao_pt, unidade, categoria, tipo
FROM indicador
ORDER BY categoria, id;
```

## 8. A interface web

O arquivo `web/clima_franca.html` é uma página única e autocontida. Ele carrega o banco de dados compactado dentro do próprio HTML e executa **SQLite real no navegador**, sem servidor e sem instalação. Basta abrir o arquivo (ou publicá-lo, por exemplo, no GitHub Pages renomeando para `index.html`).

| Aba | O que faz |
|---|---|
| **Painel** | Indicadores gerais, mapa da França continental com os postos coloridos por temperatura média, precipitação anual, insolação, vento ou dias com máxima de 30 °C ou mais, ranking top 10 e gráfico climático mensal do posto selecionado, com seus recordes de calor e frio. |
| **Consultas SQL** | Editor com 7 consultas prontas, resultado em tabela (até 500 linhas exibidas), tempo de execução e atalho Ctrl+Enter. |
| **Análises** | Altitude × temperatura média anual com linha de tendência, ano do recorde de calor de cada posto, temperatura mensal e chuva mensal. |
| **Modelo ER** | Diagrama entidade-relacionamento gerado a partir da estrutura real do banco. |
| **Sobre os dados** | Fonte, modelo e observações. |

A barra de busca localiza qualquer posto pelo nome. O tema claro ou escuro pode ser alternado pelo botão no topo.

## 9. Limitações conhecidas

- **Apenas normais e recordes.** O projeto usa as normais de 1991 a 2020 e os recordes absolutos. As séries diárias e mensais históricas e as observações SYNOP a cada três horas não fazem parte desta base.
- **Cobertura desigual.** Nem todo posto mede todos os indicadores, e algumas séries de referência são mais curtas que 1991–2020 (veja `ref_inicio` e `ref_fim`).
- **Recordes recentes.** Muitos recordes aparecem em anos recentes em parte porque várias séries de postos começam tarde, e não apenas por mudança do clima.
- **Mapa continental.** O mapa mostra apenas a França continental. Postos ultramarinos e da Córsega estão no banco, mas ficam fora do desenho.
- **Departamentos.** Os arquivos trazem apenas o número do departamento, não o nome.
- **SYNOP × postos.** Não há vínculo direto entre `estacao_synop` e `posto` nos dados de origem.
- **Dialetos.** A página usa SQLite. Os scripts de PostgreSQL, MySQL e SQL Server foram gerados a partir do mesmo modelo, com as adaptações de tipos e de carga de cada sistema. Valide a conferência final ao rodá-los.

## 10. Tecnologias

SQL (PostgreSQL, MySQL, SQL Server, SQLite) · modelagem relacional · ETL com Python e pandas · JavaScript · HTML e CSS · SQL.js (SQLite compilado para JavaScript) · visualização de dados com Canvas e SVG.

## 11. Fonte, licença e créditos

- **Fonte dos dados:** dados abertos da Météo-France. Confira na página oficial de publicação dos dados a licença de uso aplicável e mantenha a citação da fonte.
- **Código, scripts e interface:** _(escolha uma licença para o repositório, por exemplo MIT, e adicione o arquivo `LICENSE`)_.
- **Autor:** Cauã Venseguerra Nascimento.
