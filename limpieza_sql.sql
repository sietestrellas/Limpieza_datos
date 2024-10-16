-- ======================================================================== --
--                            LIMPIEZA DE DATOS SQL           
-- ========================================================================= -- 

-- =========== Preparando  y explorando los datos ================== --

-- ----- Crear una base de datos 
CREATE DATABASE IF NOT EXISTS datos;

USE datos;

-- ----- Generar una muestra de los datos
SELECT * FROM datos LIMIT 100;

-- ===========  procedimiento almacenado ================== --

Select * from datos;

-- ----- crear el procedimiento --
DELIMITER //
CREATE PROCEDURE limpiar()
BEGIN
    SELECT * FROM datos;
END //
DELIMITER ;
-- ejecutar el procedimiento
CALL limpiar();



-- # Cambiar el nombre a las columnas # --

ALTER TABLE datos CHANGE COLUMN `ï»¿Id?empleado` id_employee varchar(20)  null; 
ALTER TABLE datos CHANGE COLUMN `gÃ©nero` gender varchar(20)  null; 
ALTER TABLE datos CHANGE COLUMN  Name name varchar(40)  null;
ALTER TABLE datos CHANGE COLUMN apellido last_name varchar(40)  null;
ALTER TABLE datos CHANGE COLUMN star_date start_date varchar(20) null;


-- ----- Renombrar los nombres de las columnas con caracteres especiales
ALTER TABLE datos CHANGE COLUMN `ï»¿Id?empleado` Id_emp varchar(20) null; 

-- =========== Verificar y remover registros duplicados ================== --

-- ----- Verificar si hay registros duplicados
SELECT Id_emp, COUNT(*) AS cantidad_duplicados
FROM datos
GROUP BY Id_emp  
HAVING COUNT(*) > 1;


-- ----- Contar el número de duplicados con Subquery 
SELECT COUNT(*) AS cantidad_duplicados
FROM (
    SELECT Id_emp
    FROM datos
    GROUP BY Id_emp
    HAVING COUNT(*) > 1
) AS subquery;



-- ----- Crear una tabla temporal con valores unicos y luego hacerla "original" (permanente)

-- # cambiar el nombre de la tabla 'limpieza' por 'conduplicados'
RENAME TABLE datos TO conduplicados;

-- # crear una tabla temporal (sin datos duplicados)
CREATE TEMPORARY TABLE temp_limpieza AS 									
SELECT DISTINCT *  FROM conduplicados; 	


-- # verificar el número de registros
SELECT COUNT(*) AS original FROM conduplicados;
SELECT COUNT(*) AS temporal FROM temp_limpieza; 

-- # convertir la tabla temporal a permanente
CREATE TABLE datos AS
SELECT * FROM temp_limpieza;

-- ----- Verificar nuevamente si aún hay duplicados
SELECT COUNT(*) AS cantidad_duplicados
FROM (
    SELECT Id_emp
    FROM conduplicados 
    GROUP BY Id_emp
    HAVING COUNT(*) > 1
) AS subquery;

 -- ----- Eliminar tabla que contiene los duplicados 
 DROP TABLE conduplicados;
 
-- =========== Verificar y remover registros duplicados ================== --



-- ----- Renombrar los nombres de las columnas
ALTER TABLE datos CHANGE COLUMN `gÃ©nero` Gender varchar(20) null;
ALTER TABLE datos CHANGE COLUMN Apellido Last_name varchar(50) null;
ALTER TABLE datos CHANGE COLUMN star_date Start_date varchar(50) null;

-- ----- Revisar los tipos de datos de la tabla
DESCRIBE datos; 

-- ===========  Trabajando con texto (strings) ================== --

-- ----- Identificar nombres con espacios extra --
call limpiar();

SELECT Name FROM datos WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0; 
/

-- ----- "Ensayo" del query antes de actualizar la tabla

-- # Nombres con espacios
SELECT name, TRIM(name) AS Name
FROM datos
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;

-- # modificando nombres
UPDATE datos
SET name = TRIM(name)
WHERE LENGTH(name) - LENGTH(TRIM(name)) > 0;

-- # Apellidos con espacios
SELECT last_name, TRIM(Last_name) AS Last_name 
FROM datos
WHERE LENGTH(last_name) - LENGTH(TRIM(last_name)) > 0;

-- # modificando apellidos
UPDATE datos
SET last_name = TRIM(Last_name)
WHERE LENGTH(Last_name) - LENGTH(TRIM(Last_name)) > 0;

call limpiar();

-- ------ identificar espacios extra en medio de dos palabras



-- # Explorar si hay dos o más espacios entre dos palabras  
SELECT area FROM datos
WHERE area REGEXP '\\s{2,}';  

-- # Consultar los espacios extra 
Select area, TRIM(REGEXP_REPLACE(area, '\\s+', ' ')) as ensayo 
FROM datos; 
 
 
UPDATE datos SET area = TRIM(REGEXP_REPLACE(area, '\\s+', ' ')); 

 -- ===========  Buscar y reemplazar (textos) ================== --
-- ------ Ajustar gender
-- # ensayo
SELECT gender,  
CASE
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END as gender1
FROM datos;

-- # actualizar tabla
UPDATE datos
SET Gender = CASE
    WHEN gender = 'hombre' THEN 'Male'
    WHEN gender = 'mujer' THEN 'Female'
    ELSE 'Other'
END;
CALL limpiar();

 -- ===========  Cambiar propiedad y reemplazar datos ================== -- 
DESCRIBE datos;

ALTER TABLE datos MODIFY COLUMN Type TEXT;

SELECT type,
CASE 
	WHEN type = 1 THEN 'Remote'
    WHEN type = 0 THEN 'Hybrid'
    ELSE 'Other'
END as ejemplo
FROM datos;

UPDATE datos
SET Type = CASE
	WHEN type = 1 THEN 'Remote'
    WHEN type = 0 THEN 'Hybrid'
    ELSE 'Other'
END;
-- revisamos cambios
call limpiar();

-- ===========  Ajustar formato números ================== -- 


-- ----- consultar :reemplazar $ por un vacío y cambiar el separador de mil por vacío.
SELECT salary,  CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2)) from datos;


UPDATE datos SET salary = CAST(TRIM(REPLACE(REPLACE(salary, '$', ''), ',', '')) AS DECIMAL(15, 2));


-- ===========  Trabajando con fechas ================== --

-- ------ Cambiar el tipo de dato de las columnas de texto (strings) a fechas
DESCRIBE datos; -- hay tres fechas a ajustar (birth_day, start_day. finish_day)

-- # Birth_day # 

-- ----- Identificar como están las fechas de fecha
SELECT birth_date FROM datos; 
call limpiar(); -

-- ----- "ensayo" - dar formato a la fecha 
SELECT birth_date, CASE
    WHEN birth_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birth_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(birth_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
END AS new_birth_date
FROM datos;


-- ----- Actualizar la tabla
UPDATE datos
SET birth_date = CASE
	WHEN birth_date LIKE '%/%' THEN date_format(str_to_date(birth_date, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN birth_date LIKE '%-%' THEN date_format(str_to_date(birth_date, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;

-- Cambiar el tipo de dato de la columna 
ALTER TABLE datos MODIFY COLUMN birth_date date;
DESCRIBE datos; 

-- # Start_date (Se repite el proceso)
-- ----- Identificar como están las fechas de fecha
SELECT start_date FROM datos; 
call limp(); 

-- ----- "ensayo" - dar formato a la fecha 
SELECT start_date, CASE
	WHEN start_date LIKE '%/%' THEN date_format(str_to_date(start_date, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN start_date LIKE '%-%' THEN date_format(str_to_date(start_date, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END AS new_start_date
FROM datos;

-- ----- Actualizar la tabla
UPDATE datos
SET start_date = CASE
	WHEN start_date LIKE '%/%' THEN date_format(str_to_date(start_date, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN start_date LIKE '%-%' THEN date_format(str_to_date(start_date, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL
END;

-- Cambiar el tipo de dato de la columna 
ALTER TABLE datos MODIFY COLUMN start_date DATE;
DESCRIBE datos;



-- ===========  Actualizaciones de fecha en la tabla  ================== --

-- ----- Copia de seguridad de la columna finish_date
call limpiar();
ALTER TABLE datos ADD COLUMN date_backup TEXT; 
UPDATE datos SET date_backup = finish_date; --

-- # Actualizar la fecha a marca de tiempo: (TIMESTAMP ; DATETIME)
 Select finish_date, str_to_date(finish_date, '%Y-%m-%d %H:%i:%s UTC')  as formato from datos; -- (UTC)
 

UPDATE datos
	SET finish_date = str_to_date(finish_date, '%Y-%m-%d %H:%i:%s UTC') 
	WHERE finish_date <> '';
    
call limpiar();

-- --------- Dividir la finish_date en fecha y hora

 -- # Crear las columnas que albergarán los nuevos datos 
ALTER TABLE datos
	ADD COLUMN fecha DATE,
	ADD COLUMN hora TIME;
    
-- # actualizar los valores de dichas columnas
UPDATE datos
SET fecha = DATE(finish_date),
    hora = TIME(finish_date)
WHERE finish_date IS NOT NULL AND finish_date <> '';

 -- # Valores en blanco a nulos
UPDATE datos SET finish_date = NULL WHERE finish_date = '';

-- # Actualizar la propiedad
ALTER TABLE datos MODIFY COLUMN finish_date DATETIME;

-- # Revisar los datos
SELECT * FROM datos; 
CALL limpiar();
DESCRIBE datos;

-- ========= Cálculos con fechas ====== -- 

-- # Agregar columna para albergar la edad
ALTER TABLE datos ADD COLUMN age INT;
call limpiar();

SELECT name,birth_date, start_date, TIMESTAMPDIFF(YEAR, birth_date, start_date) AS edad_de_ingreso
FROM datos;


-- # Actualizar los datos en la columna edad
UPDATE datos
SET age = timestampdiff(YEAR, birth_date, CURDATE()); 

call limpiar;

-- ============ creando columnas adicionales ================= -- 

select CONCAT(SUBSTRING_INDEX(Name, ' ', 1),'_', SUBSTRING(Last_name, 1, 4), '.',SUBSTRING(Type, 1, 1), '@consultoria.com') as email from datos;


ALTER TABLE datos
ADD COLUMN email VARCHAR(100);

UPDATE datos
SET email = CONCAT(SUBSTRING_INDEX(Name, ' ', 1),'_', SUBSTRING(Last_name, 1, 4), '.',SUBSTRING(Type, 1, 1), '@consulting.com'); 

CALL limpiar();

-- ============ creando y exportando mi set de datos definitivo ================= -- 

SELECT * FROM datos
WHERE finish_date <= CURDATE() OR finish_date IS NULL
ORDER BY area, Name;

SELECT area, COUNT(*) AS cantidad_empleados FROM datos
GROUP BY area
ORDER BY cantidad_empleados DESC;