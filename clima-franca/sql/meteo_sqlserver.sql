-- Projeto: Clima da França (Météo-France) · Autor: Cauã Venseguerra Nascimento
-- SQL Server 2017+. Ajuste o caminho dos CSVs (precisa ser acessível pelo servidor).
IF DB_ID('meteo') IS NULL CREATE DATABASE meteo;
GO
USE meteo;
GO

-- ===== 1. Tabelas finais (modelo normalizado) =====
DROP TABLE IF EXISTS recorde;
DROP TABLE IF EXISTS normal;
DROP TABLE IF EXISTS estacao_synop;
DROP TABLE IF EXISTS posto;
DROP TABLE IF EXISTS indicador;
CREATE TABLE indicador(id INT PRIMARY KEY, codigo NVARCHAR(200) NOT NULL UNIQUE, descricao_pt NVARCHAR(200), descricao_fr NVARCHAR(200), unidade NVARCHAR(200), categoria NVARCHAR(200), tipo NVARCHAR(200));
CREATE TABLE posto(numero_poste BIGINT PRIMARY KEY, nome NVARCHAR(200), departamento INT, latitude FLOAT, longitude FLOAT, altitude INT, data_edicao DATE);
CREATE TABLE estacao_synop(indicativo_omm INT PRIMARY KEY, indicativo_wigos NVARCHAR(200), nome NVARCHAR(200), latitude FLOAT, longitude FLOAT, altitude INT, data_abertura DATE, ano_inicio_obs INT, ano_fim_obs INT);
CREATE TABLE normal(numero_poste BIGINT NOT NULL, indicador_id INT NOT NULL, periodo INT NOT NULL, valor FLOAT, ref_inicio INT, ref_fim INT, PRIMARY KEY(numero_poste,indicador_id,periodo));
CREATE TABLE recorde(numero_poste BIGINT NOT NULL, indicador_id INT NOT NULL, periodo INT NOT NULL, valor FLOAT, dia INT, ano INT, serie_inicio DATE, serie_fim DATE, PRIMARY KEY(numero_poste,indicador_id,periodo));
CREATE INDEX ix_normal_ind ON normal(indicador_id,periodo);
CREATE INDEX ix_recorde_ind ON recorde(indicador_id,periodo);
-- periodo: 0 = valor anual, 1..12 = mês

-- ===== 2. Catálogo de indicadores (40) =====
INSERT INTO indicador VALUES (1,'degres_jours_unifies','Graus-dias unificados','Degrés Jours Unifiés (Moyenne en °C)','celsius_degree','graus_dias','media');
INSERT INTO indicador VALUES (2,'duree_insolation_moyenne','Insolação média (horas)','Durée d''insolation (Moyenne en heures)','hour','insolacao_radiacao','media');
INSERT INTO indicador VALUES (3,'evapotranspiration_potentielle_moyenne','Evapotranspiração potencial (Penman, mm)','Evapotranspiration Potentielle (ETP Penman moyenne en mm)','millimeter','evapotranspiracao','media');
INSERT INTO indicador VALUES (4,'nombre_jours_brouillard','Dias com nevoeiro','Nombre moyen de jours avec Brouillard','day','fenomenos','contagem_dias');
INSERT INTO indicador VALUES (5,'nombre_jours_grele','Dias com granizo','Nombre moyen de jours avec Grêle','day','fenomenos','contagem_dias');
INSERT INTO indicador VALUES (6,'nombre_jours_neige','Dias com neve','Nombre moyen de jours avec Neige','day','fenomenos','contagem_dias');
INSERT INTO indicador VALUES (7,'nombre_jours_orage','Dias com tempestade','Nombre moyen de jours avec Orage','day','fenomenos','contagem_dias');
INSERT INTO indicador VALUES (8,'nombre_jours_rafale_sup_16_m_s','Dias com rajada ≥ 16 m/s','Nombre moyen de jours avec rafales >= 16 m/s','day','vento','contagem_dias');
INSERT INTO indicador VALUES (9,'nombre_jours_rafale_sup_28_m_s','Dias com rajada ≥ 28 m/s','Nombre moyen de jours avec rafales >= 28 m/s','day','vento','contagem_dias');
INSERT INTO indicador VALUES (10,'nombre_jours_rr_sup_100_mm','Dias com chuva ≥ 100 mm','Nombre moyen de jours avec Rr >= 100 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (11,'nombre_jours_rr_sup_10_mm','Dias com chuva ≥ 10 mm','Nombre moyen de jours avec Rr >= 10 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (12,'nombre_jours_rr_sup_1_mm','Dias com chuva ≥ 1 mm','Nombre moyen de jours avec Rr >= 1 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (13,'nombre_jours_rr_sup_30_mm','Dias com chuva ≥ 30 mm','Nombre moyen de jours avec Rr >= 30 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (14,'nombre_jours_rr_sup_50_mm','Dias com chuva ≥ 50 mm','Nombre moyen de jours avec Rr >= 50 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (15,'nombre_jours_rr_sup_5_mm','Dias com chuva ≥ 5 mm','Nombre moyen de jours avec Rr >= 5 mm','day','precipitacao','contagem_dias');
INSERT INTO indicador VALUES (16,'nombre_jours_tn_inf_0c','Dias com Tn ≤ 0 °C','Nombre moyen de jours avec Tn <= 0°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (17,'nombre_jours_tn_inf_10c','Dias com Tn ≤ 10 °C','Nombre moyen de jours avec Tn <= 10°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (18,'nombre_jours_tn_inf_15c','Dias com Tn ≤ 15 °C','Nombre moyen de jours avec Tn <= 15°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (19,'nombre_jours_tn_inf_20c','Dias com Tn ≤ 20 °C','Nombre moyen de jours avec Tn <= 20°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (20,'nombre_jours_tn_inf_moins_10c','Dias com Tn ≤ −10 °C','Nombre moyen de jours avec Tn <= -10°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (21,'nombre_jours_tn_inf_moins_5c','Dias com Tn ≤ −5 °C','Nombre moyen de jours avec Tn <= -5°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (22,'nombre_jours_tn_sup_20c','Dias com Tn ≥ 20 °C','Nombre moyen de jours avec Tn >= 20°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (23,'nombre_jours_tn_sup_25c','Dias com Tn ≥ 25 °C','Nombre moyen de jours avec Tn >= 25°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (24,'nombre_jours_tx_inf_0c','Dias com Tx ≤ 0 °C','Nombre moyen de jours avec Tx <= 0°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (25,'nombre_jours_tx_inf_20c','Dias com Tx ≤ 20 °C','Nombre moyen de jours avec Tx <= 20°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (26,'nombre_jours_tx_inf_27c','Dias com Tx ≤ 27 °C','Nombre moyen de jours avec Tx <= 27°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (27,'nombre_jours_tx_sup_25c','Dias com Tx ≥ 25 °C','Nombre moyen de jours avec Tx >= 25°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (28,'nombre_jours_tx_sup_30c','Dias com Tx ≥ 30 °C','Nombre moyen de jours avec Tx >= 30°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (29,'nombre_jours_tx_sup_32c','Dias com Tx ≥ 32 °C','Nombre moyen de jours avec Tx >= 32°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (30,'nombre_jours_tx_sup_35c','Dias com Tx ≥ 35 °C','Nombre moyen de jours avec Tx >= 35°C','day','temperatura','contagem_dias');
INSERT INTO indicador VALUES (31,'precipitation_hauteur_moyenne','Precipitação média mensal (mm)','Précipitations : Hauteur moyenne mensuelle (mm)','millimeter','precipitacao','media');
INSERT INTO indicador VALUES (32,'precipitation_quotidienne_maximale','Precipitação diária máxima – recorde (mm)','Précipitations : Hauteur quotidienne maximale (mm)','millimeter','precipitacao','recorde');
INSERT INTO indicador VALUES (33,'rafale_maximale_absolue','Rajada máxima de vento – recorde (m/s)','Rafale maximale de vent (m/s)','meter_per_second','vento','recorde');
INSERT INTO indicador VALUES (34,'rayonnement_global_moyen','Radiação global média (J/cm²)','Rayonnement global (Moyenne en J/cm²)','joule_per_square_centimeter','insolacao_radiacao','media');
INSERT INTO indicador VALUES (35,'temperature_maximale_absolue','Temperatura máxima – recorde (°C)','La température la plus élevée (°C)','celsius_degree','temperatura','recorde');
INSERT INTO indicador VALUES (36,'temperature_maximale_moyenne','Temperatura máxima média (°C)','Température maximale (Moyenne en °C)','celsius_degree','temperatura','media');
INSERT INTO indicador VALUES (37,'temperature_minimale_absolue','Temperatura mínima – recorde (°C)','La température la plus basse (°C)','celsius_degree','temperatura','recorde');
INSERT INTO indicador VALUES (38,'temperature_minimale_moyenne','Temperatura mínima média (°C)','Température minimale (Moyenne en °C)','celsius_degree','temperatura','media');
INSERT INTO indicador VALUES (39,'temperature_moyenne','Temperatura média (°C)','Température moyenne (Moyenne en °C)','celsius_degree','temperatura','media');
INSERT INTO indicador VALUES (40,'vitesse_vent_moyenne','Velocidade média do vento a 10 min (m/s)','Vitesse du vent moyenné sur 10 mn (Moyenne en m/s)','meter_per_second','vento','media');

-- ===== 3. Tabelas de estágio (texto bruto dos CSVs) =====
DROP TABLE IF EXISTS stg_normale;DROP TABLE IF EXISTS stg_posto;DROP TABLE IF EXISTS stg_synop;
CREATE TABLE stg_normale(numero_poste NVARCHAR(255), indicateur NVARCHAR(255), periode NVARCHAR(255), valeur NVARCHAR(255), unite NVARCHAR(255), libelle_indicateur NVARCHAR(255), annee_debut_reference NVARCHAR(255), annee_fin_reference NVARCHAR(255), date_debut_record NVARCHAR(255), date_fin_record NVARCHAR(255), jour_record NVARCHAR(255), annee_record NVARCHAR(255));
CREATE TABLE stg_posto(numero_poste NVARCHAR(255), nom_poste NVARCHAR(255), id_departement NVARCHAR(255), latitude NVARCHAR(255), longitude NVARCHAR(255), altitude NVARCHAR(255), date_edition NVARCHAR(255), geolocalisation NVARCHAR(255));
CREATE TABLE stg_synop(indicatif_omm NVARCHAR(255), indicatif_wigos NVARCHAR(255), nom_station NVARCHAR(255), latitude NVARCHAR(255), longitude NVARCHAR(255), altitude NVARCHAR(255), date_ouverture NVARCHAR(255), annee_debut_observation NVARCHAR(255), annee_fin_observation NVARCHAR(255), geolocalisation NVARCHAR(255));
GO
BULK INSERT stg_normale FROM 'C:\dados\fr_meteofrance_normale_climatologique.csv' WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');
BULK INSERT stg_posto FROM 'C:\dados\fr_meteofrance_station_climatologique.csv' WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');
BULK INSERT stg_synop FROM 'C:\dados\fr_meteofrance_station_synop.csv' WITH (FORMAT='CSV', FIELDQUOTE='"', FIRSTROW=2, CODEPAGE='65001', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a');
GO

-- ===== 4. Carga nas tabelas finais =====
INSERT INTO posto SELECT CAST(numero_poste AS BIGINT), nom_poste, CAST(CAST(NULLIF(id_departement,'') AS DECIMAL(14,6)) AS INT), CAST(NULLIF(latitude,'') AS DECIMAL(14,6)), CAST(NULLIF(longitude,'') AS DECIMAL(14,6)), CAST(CAST(NULLIF(altitude,'') AS DECIMAL(14,6)) AS INT), CAST(NULLIF(date_edition,'') AS DATE) FROM stg_posto;
INSERT INTO estacao_synop SELECT CAST(CAST(NULLIF(indicatif_omm,'') AS DECIMAL(14,6)) AS INT), indicatif_wigos, nom_station, CAST(NULLIF(latitude,'') AS DECIMAL(14,6)), CAST(NULLIF(longitude,'') AS DECIMAL(14,6)), CAST(CAST(NULLIF(altitude,'') AS DECIMAL(14,6)) AS INT), CAST(NULLIF(date_ouverture,'') AS DATE), CAST(CAST(NULLIF(annee_debut_observation,'') AS DECIMAL(14,6)) AS INT), CAST(CAST(NULLIF(annee_fin_observation,'') AS DECIMAL(14,6)) AS INT) FROM stg_synop;
INSERT INTO normal SELECT CAST(s.numero_poste AS BIGINT), i.id, CASE WHEN s.periode='annee' THEN 0 ELSE CAST(CAST(NULLIF(s.periode,'') AS DECIMAL(14,6)) AS INT) END, CAST(NULLIF(s.valeur,'') AS DECIMAL(14,6)), CAST(CAST(NULLIF(s.annee_debut_reference,'') AS DECIMAL(14,6)) AS INT), CAST(CAST(NULLIF(s.annee_fin_reference,'') AS DECIMAL(14,6)) AS INT)
FROM stg_normale s JOIN indicador i ON i.codigo=s.indicateur WHERE i.tipo<>'recorde';
INSERT INTO recorde SELECT CAST(s.numero_poste AS BIGINT), i.id, CASE WHEN s.periode='annee' THEN 0 ELSE CAST(CAST(NULLIF(s.periode,'') AS DECIMAL(14,6)) AS INT) END, CAST(NULLIF(s.valeur,'') AS DECIMAL(14,6)), CAST(CAST(NULLIF(s.jour_record,'') AS DECIMAL(14,6)) AS INT), CAST(CAST(NULLIF(s.annee_record,'') AS DECIMAL(14,6)) AS INT), CAST(NULLIF(s.date_debut_record,'') AS DATE), CAST(NULLIF(s.date_fin_record,'') AS DATE)
FROM stg_normale s JOIN indicador i ON i.codigo=s.indicateur WHERE i.tipo='recorde';
DROP TABLE IF EXISTS stg_normale;DROP TABLE IF EXISTS stg_posto;DROP TABLE IF EXISTS stg_synop;

ALTER TABLE normal ADD CONSTRAINT fk_n_posto FOREIGN KEY(numero_poste) REFERENCES posto(numero_poste);
ALTER TABLE normal ADD CONSTRAINT fk_n_ind FOREIGN KEY(indicador_id) REFERENCES indicador(id);
ALTER TABLE recorde ADD CONSTRAINT fk_r_posto FOREIGN KEY(numero_poste) REFERENCES posto(numero_poste);
ALTER TABLE recorde ADD CONSTRAINT fk_r_ind FOREIGN KEY(indicador_id) REFERENCES indicador(id);

-- ===== 5. Conferência: esperado 1574 | 190 | 331420 | 70839 =====
SELECT (SELECT COUNT(*) FROM posto) AS postos, (SELECT COUNT(*) FROM estacao_synop) AS synop, (SELECT COUNT(*) FROM normal) AS normais, (SELECT COUNT(*) FROM recorde) AS recordes;

-- ===== 6. Consulta de exemplo: 10 postos com a maior temperatura já registrada =====
SELECT TOP 10 p.nome, p.altitude, r.valor AS tmax_c, r.ano
FROM recorde r JOIN posto p ON p.numero_poste=r.numero_poste
WHERE r.indicador_id=(SELECT id FROM indicador WHERE codigo='temperature_maximale_absolue') AND r.periodo=0
ORDER BY r.valor DESC;
