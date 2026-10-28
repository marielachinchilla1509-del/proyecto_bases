DROP DATABASE IF EXISTS simulador_aulas;

CREATE DATABASE simulador_aulas
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE simulador_aulas;


CREATE TABLE periodo (
    id_periodo INT AUTO_INCREMENT PRIMARY KEY,
    anio_academico SMALLINT NOT NULL,
    ciclo TINYINT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    UNIQUE (anio_academico, ciclo),
    CHECK (ciclo BETWEEN 1 AND 3),
    CHECK (fecha_fin >= fecha_inicio)
);


CREATE TABLE carrera (
    id_carrera INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL UNIQUE,
    es_informatica BOOLEAN NOT NULL DEFAULT FALSE
);


CREATE TABLE curso (
    id_curso INT AUTO_INCREMENT PRIMARY KEY,
    id_carrera INT NOT NULL,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    semestre_malla TINYINT NULL,
    horas_teoria TINYINT NULL,
    horas_practica TINYINT NULL,
    FOREIGN KEY (id_carrera)
        REFERENCES carrera(id_carrera)
);


CREATE TABLE espacio (
    id_espacio INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    tipo ENUM(
        'AULA',
        'LABORATORIO',
        'GIMNASIO',
        'MULTIUSOS'
    ) NOT NULL,
    capacidad SMALLINT NOT NULL DEFAULT 35,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (capacidad > 0)
);


CREATE TABLE grupo (
    id_grupo INT AUTO_INCREMENT PRIMARY KEY,
    id_curso INT NOT NULL,
    id_periodo INT NOT NULL,
    numero_grupo VARCHAR(10) NOT NULL,
    cupo SMALLINT NOT NULL,
    modalidad ENUM(
        'PRESENCIAL',
        'VIRTUAL',
        'HIBRIDA'
    ) NOT NULL,
    docente VARCHAR(120) NULL,
    FOREIGN KEY (id_curso)
        REFERENCES curso(id_curso),
    FOREIGN KEY (id_periodo)
        REFERENCES periodo(id_periodo),
    UNIQUE (id_periodo, id_curso, numero_grupo),
    CHECK (cupo > 0)
);


CREATE TABLE sesion (
    id_sesion INT AUTO_INCREMENT PRIMARY KEY,
    id_grupo INT NOT NULL,
    dia_semana TINYINT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    modalidad ENUM(
        'PRESENCIAL',
        'VIRTUAL'
    ) NOT NULL DEFAULT 'PRESENCIAL',
    actividad ENUM(
        'NO_ESPECIFICADA',
        'TEORIA',
        'PRACTICA',
        'DEPORTIVA'
    ) NOT NULL DEFAULT 'NO_ESPECIFICADA',
    tipo_obligatorio ENUM(
        'AULA',
        'LABORATORIO',
        'GIMNASIO',
        'MULTIUSOS'
    ) NULL,
    FOREIGN KEY (id_grupo)
        REFERENCES grupo(id_grupo),
    CHECK (dia_semana BETWEEN 1 AND 6),
    CHECK (hora_inicio < hora_fin)
);


CREATE TABLE asignacion (
    id_asignacion INT AUTO_INCREMENT PRIMARY KEY,
    id_sesion INT NOT NULL UNIQUE,
    id_espacio INT NOT NULL,
    fecha_asignacion TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_sesion)
        REFERENCES sesion(id_sesion),
    FOREIGN KEY (id_espacio)
        REFERENCES espacio(id_espacio)
);


INSERT INTO periodo (
    anio_academico,
    ciclo,
    fecha_inicio,
    fecha_fin
)
VALUES
(2026, 3, '2027-01-01', '2027-02-28'),
(2027, 1, '2027-03-01', '2027-07-31'),
(2027, 2, '2027-08-01', '2027-11-30');


INSERT INTO carrera (nombre, es_informatica)
VALUES
('Enseñanza del Inglés', 0),
('Turismo', 0),
('Informática Empresarial', 1),
('Diseño y Artes', 0),
('Matemática', 0),
('Administración Aduanera', 0);


INSERT INTO espacio (nombre, tipo, capacidad)
VALUES
('Aula 1', 'AULA', 35),
('Aula 2', 'AULA', 35),
('Aula 3', 'AULA', 35),
('Aula 4', 'LABORATORIO', 35),
('Aula 5', 'AULA', 35),
('Aula 6', 'AULA', 35),
('Aula 7', 'AULA', 35),
('Aula 8', 'AULA', 35),
('Aula 9', 'AULA', 35),
('Aula 10', 'AULA', 35),
('Aula 11', 'AULA', 35),
('Gimnasio', 'GIMNASIO', 35),
('Salón multiusos', 'MULTIUSOS', 35);


DELIMITER //

CREATE PROCEDURE sp_cargar_grupo(
    IN p_carrera VARCHAR(120),
    IN p_codigo VARCHAR(20),
    IN p_nombre VARCHAR(150),
    IN p_cupo SMALLINT,
    IN p_modalidad VARCHAR(15),
    IN p_horarios TEXT
)
BEGIN

    DECLARE v_carrera INT;
    DECLARE v_curso INT;
    DECLARE v_grupo INT;
    DECLARE v_pos INT;
    DECLARE v_pieza VARCHAR(50);
    DECLARE v_dia INT;
    DECLARE v_ini VARCHAR(5);
    DECLARE v_fin VARCHAR(5);

    SELECT id_carrera
    INTO v_carrera
    FROM carrera
    WHERE nombre = p_carrera;

    INSERT INTO curso (
        id_carrera,
        codigo,
        nombre
    )
    VALUES (
        v_carrera,
        p_codigo,
        p_nombre
    );

    SET v_curso = LAST_INSERT_ID();

    INSERT INTO grupo (
        id_curso,
        id_periodo,
        numero_grupo,
        cupo,
        modalidad
    )
    VALUES (
        v_curso,
        1,
        '01',
        p_cupo,
        p_modalidad
    );

    SET v_grupo = LAST_INSERT_ID();

    WHILE CHAR_LENGTH(p_horarios) > 0 DO

        SET v_pos = LOCATE(';', p_horarios);

        IF v_pos = 0 THEN

            SET v_pieza = p_horarios;
            SET p_horarios = '';

        ELSE

            SET v_pieza = LEFT(p_horarios, v_pos - 1);

            SET p_horarios =
                SUBSTRING(p_horarios, v_pos + 1);

        END IF;

        SET v_dia = CAST(
            SUBSTRING_INDEX(v_pieza, ',', 1)
            AS UNSIGNED
        );

        SET v_ini = SUBSTRING_INDEX(
            SUBSTRING_INDEX(v_pieza, ',', 2),
            ',',
            -1
        );

        SET v_fin = SUBSTRING_INDEX(
            v_pieza,
            ',',
            -1
        );

        INSERT INTO sesion (
            id_grupo,
            dia_semana,
            hora_inicio,
            hora_fin,
            modalidad
        )
        VALUES (
            v_grupo,
            v_dia,
            CONCAT(v_ini, ':00'),
            CONCAT(v_fin, ':00'),
            IF(
                p_modalidad = 'VIRTUAL',
                'VIRTUAL',
                'PRESENCIAL'
            )
        );

    END WHILE;

END//

DELIMITER ;


CALL sp_cargar_grupo(
'Enseñanza del Inglés',
'IO-5210',
'Comunicación Escrita II',
30,
'PRESENCIAL',
'2,08:00,11:50;4,08:00,11:50'
);


CALL sp_cargar_grupo(
'Enseñanza del Inglés',
'IO-5220',
'Comunicación Escrita III',
30,
'PRESENCIAL',
'1,08:00,11:50;3,08:00,11:50'
);


CALL sp_cargar_grupo(
'Turismo',
'MA-0125',
'Matemática Elemental',
25,
'PRESENCIAL',
'1,13:00,16:50;3,08:00,11:50;5,08:00,11:50'
);


CALL sp_cargar_grupo(
'Turismo',
'PI0044',
'Comunicación y Expresión Oral y Escrita en Español',
30,
'PRESENCIAL',
'1,08:00,10:50;3,08:00,10:50'
);


CALL sp_cargar_grupo(
'Turismo',
'TE0209',
'Geografía Turística de Costa Rica',
35,
'PRESENCIAL',
'2,08:00,11:50;3,13:00,16:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'IF-0004',
'Desarrollo de Software II',
25,
'PRESENCIAL',
'1,08:00,11:50;2,08:00,11:50;3,08:00,11:50;4,08:00,11:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'IF-0005',
'Matemáticas Discretas para Informática Empresarial',
25,
'PRESENCIAL',
'1,13:00,16:50;2,13:00,15:50;3,13:00,15:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'IF-0008',
'Cálculo I para Informática Empresarial',
25,
'PRESENCIAL',
'1,13:00,16:50;2,13:00,15:50;5,08:00,10:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'IF-0013',
'Inglés para Informática Empresarial',
30,
'PRESENCIAL',
'2,08:00,11:50;3,08:00,11:50;4,08:00,11:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'MA0320',
'Estructuras Matemáticas Discretas',
10,
'PRESENCIAL',
'2,13:00,16:50;4,13:00,15:50;5,13:00,15:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'MA0322',
'Álgebra Lineal',
25,
'PRESENCIAL',
'1,08:00,10:50;2,08:00,10:50;3,08:00,11:50'
);


CALL sp_cargar_grupo(
'Informática Empresarial',
'XS0105',
'Estadística para Informáticos',
8,
'PRESENCIAL',
'1,13:00,16:50;3,13:00,16:50'
);


CALL sp_cargar_grupo(
'Diseño y Artes',
'AP-0905',
'Taller de Tipografía',
20,
'PRESENCIAL',
'2,13:00,16:50;4,13:00,16:50'
);


CALL sp_cargar_grupo(
'Diseño y Artes',
'AP-6025',
'Dibujo Paisaje',
25,
'PRESENCIAL',
'2,08:00,11:50;4,08:00,11:50'
);


CALL sp_cargar_grupo(
'Diseño y Artes',
'AP-7101',
'Diseño Gráfico I',
9,
'PRESENCIAL',
'1,08:00,11:50;3,08:00,11:50;5,08:00,11:50'
);


CALL sp_cargar_grupo(
'Diseño y Artes',
'AP-7102',
'Taller Gráfico I',
9,
'PRESENCIAL',
'1,13:00,16:50;3,13:00,16:50;5,13:00,16:50'
);


CALL sp_cargar_grupo(
'Matemática',
'MA0003',
'Fundamentos de la Matemática',
15,
'PRESENCIAL',
'1,13:00,15:50;3,13:00,16:50;4,08:00,10:50'
);


CALL sp_cargar_grupo(
'Matemática',
'MA0019',
'Funciones Riemann Integrables',
4,
'PRESENCIAL',
'2,08:00,10:50;3,08:00,11:50;4,08:00,10:50'
);


CALL sp_cargar_grupo(
'Matemática',
'MA0022',
'Geometría Analítica',
2,
'PRESENCIAL',
'2,08:00,10:50;3,08:00,11:50;4,08:00,10:50'
);


CALL sp_cargar_grupo(
'Matemática',
'MA-1001',
'Cálculo I',
25,
'PRESENCIAL',
'1,13:00,16:50;2,08:00,10:50;3,08:00,10:50'
);


CALL sp_cargar_grupo(
'Administración Aduanera',
'LM0348',
'Inglés para Administración y Comercio I',
3,
'PRESENCIAL',
'1,08:00,11:50;3,08:00,11:50'
);


CALL sp_cargar_grupo(
'Administración Aduanera',
'XP0252',
'Mercadología y Clasificación IV',
2,
'VIRTUAL',
'2,17:00,20:50;4,17:00,19:50'
);


CALL sp_cargar_grupo(
'Administración Aduanera',
'XP0293',
'Elementos Esenciales en los Negocios Internacionales',
30,
'VIRTUAL',
'1,09:00,11:50;3,09:00,11:50'
);


CALL sp_cargar_grupo(
'Administración Aduanera',
'XP0503',
'Valoración Aduanera de Mercancías I',
1,
'VIRTUAL',
'1,17:00,19:50;5,17:00,19:50'
);


DROP PROCEDURE sp_cargar_grupo;


DELIMITER //

CREATE PROCEDURE sp_asignar_aulas(IN p_periodo INT)
BEGIN
    DECLARE terminado BOOLEAN DEFAULT FALSE;
    DECLARE v_sesion INT;
    DECLARE v_cupo INT;
    DECLARE v_dia TINYINT;
    DECLARE v_inicio TIME;
    DECLARE v_fin TIME;
    DECLARE v_info BOOLEAN;
    DECLARE v_tipo VARCHAR(20);
    DECLARE v_espacio INT;
    DECLARE v_lock INT DEFAULT 0;
    DECLARE v_safe_updates INT DEFAULT 1;

    DECLARE cur CURSOR FOR
        SELECT
            s.id_sesion,
            g.cupo,
            s.dia_semana,
            s.hora_inicio,
            s.hora_fin,
            c.es_informatica,
            COALESCE(s.tipo_obligatorio, '')
        FROM sesion s
        JOIN grupo g
            ON g.id_grupo = s.id_grupo
        JOIN curso cu
            ON cu.id_curso = g.id_curso
        JOIN carrera c
            ON c.id_carrera = cu.id_carrera
        WHERE g.id_periodo = p_periodo
          AND s.modalidad = 'PRESENCIAL'
        ORDER BY
            CASE
                WHEN c.es_informatica = 1 THEN 0
                WHEN s.tipo_obligatorio = 'LABORATORIO' THEN 1
                ELSE 2
            END,
            s.dia_semana,
            s.hora_inicio,
            s.id_sesion;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET terminado = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET SESSION SQL_SAFE_UPDATES = v_safe_updates;

        IF v_lock = 1 THEN
            DO RELEASE_LOCK('simulador_asignacion_aulas');
        END IF;

        RESIGNAL;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM periodo
        WHERE id_periodo = p_periodo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El periodo solicitado no existe';
    END IF;

    SET v_safe_updates = @@SESSION.SQL_SAFE_UPDATES;

    SELECT GET_LOCK('simulador_asignacion_aulas', 10)
    INTO v_lock;

    IF v_lock IS NULL OR v_lock <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se pudo adquirir bloqueo de asignacion';
    END IF;

    SET SESSION SQL_SAFE_UPDATES = 0;

    START TRANSACTION;

    DELETE a
    FROM asignacion a
    JOIN sesion s
        ON s.id_sesion = a.id_sesion
    JOIN grupo g
        ON g.id_grupo = s.id_grupo
    WHERE g.id_periodo = p_periodo;

    OPEN cur;

    bucle: LOOP

        FETCH cur INTO
            v_sesion,
            v_cupo,
            v_dia,
            v_inicio,
            v_fin,
            v_info,
            v_tipo;

        IF terminado THEN
            LEAVE bucle;
        END IF;

        SET v_espacio = NULL;

        IF v_inicio < '13:00:00'
           AND v_fin > '12:00:00' THEN
            ITERATE bucle;
        END IF;

        BEGIN
            DECLARE espacio_no_encontrado BOOLEAN DEFAULT FALSE;

            DECLARE CONTINUE HANDLER FOR NOT FOUND
                SET espacio_no_encontrado = TRUE;

            SELECT e.id_espacio
            INTO v_espacio
            FROM espacio e
            WHERE e.activo = 1
              AND e.capacidad >= v_cupo
              AND (
                    (
                        v_tipo <> ''
                        AND e.tipo = v_tipo
                    )
                    OR
                    (
                        v_tipo = ''
                        AND (
                            e.tipo = 'AULA'
                            OR (
                                v_info = 1
                                AND e.tipo = 'LABORATORIO'
                            )
                        )
                    )
              )
              AND NOT EXISTS (
                    SELECT 1
                    FROM asignacion a
                    JOIN sesion s2
                        ON s2.id_sesion = a.id_sesion
                    JOIN grupo g2
                        ON g2.id_grupo = s2.id_grupo
                    WHERE a.id_espacio = e.id_espacio
                      AND g2.id_periodo = p_periodo
                      AND s2.dia_semana = v_dia
                      AND v_inicio < s2.hora_fin
                      AND v_fin > s2.hora_inicio
              )
            ORDER BY
                CASE
                    WHEN v_info = 1
                         AND e.tipo = 'LABORATORIO' THEN 0
                    WHEN e.tipo = 'AULA' THEN 1
                    ELSE 2
                END,
                e.id_espacio
            LIMIT 1;

            IF espacio_no_encontrado THEN
                SET v_espacio = NULL;
            END IF;
        END;

        IF v_espacio IS NOT NULL THEN
            INSERT INTO asignacion (
                id_sesion,
                id_espacio
            )
            VALUES (
                v_sesion,
                v_espacio
            );
        END IF;

    END LOOP;

    CLOSE cur;

    COMMIT;

    SET SESSION SQL_SAFE_UPDATES = v_safe_updates;

    DO RELEASE_LOCK('simulador_asignacion_aulas');

END//

DELIMITER ;


CALL sp_asignar_aulas(1);


SELECT
    COUNT(*) AS total_asignaciones
FROM asignacion;


SELECT
    cu.codigo,
    cu.nombre AS curso,
    g.numero_grupo,

    ELT(
        s.dia_semana,
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado'
    ) AS dia,

    s.hora_inicio,
    s.hora_fin,
    g.cupo,

    COALESCE(
        e.nombre,
        IF(
            s.modalidad = 'VIRTUAL',
            'NO REQUIERE',
            'SIN DISPONIBILIDAD'
        )
    ) AS aula

FROM sesion s

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

LEFT JOIN asignacion a
    ON a.id_sesion = s.id_sesion

LEFT JOIN espacio e
    ON e.id_espacio = a.id_espacio

WHERE g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio,
    cu.codigo;


SELECT
    cu.codigo,
    cu.nombre AS curso,
    e.nombre AS laboratorio,
    s.dia_semana,
    s.hora_inicio,
    s.hora_fin

FROM asignacion a

JOIN espacio e
    ON e.id_espacio = a.id_espacio

JOIN sesion s
    ON s.id_sesion = a.id_sesion

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

WHERE e.tipo = 'LABORATORIO'
  AND g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio;


SELECT
    a.id_asignacion AS asignacion_1,
    b.id_asignacion AS asignacion_2,
    e.nombre AS espacio,
    sa.dia_semana

FROM asignacion a

JOIN asignacion b
    ON a.id_asignacion < b.id_asignacion

JOIN sesion sa
    ON sa.id_sesion = a.id_sesion

JOIN sesion sb
    ON sb.id_sesion = b.id_sesion

JOIN grupo ga
    ON ga.id_grupo = sa.id_grupo

JOIN grupo gb
    ON gb.id_grupo = sb.id_grupo

JOIN espacio e
    ON e.id_espacio = a.id_espacio

WHERE a.id_espacio = b.id_espacio
  AND ga.id_periodo = gb.id_periodo
  AND sa.dia_semana = sb.dia_semana
  AND sa.hora_inicio < sb.hora_fin
  AND sa.hora_fin > sb.hora_inicio;


SELECT
    cu.codigo,
    cu.nombre AS curso,
    s.dia_semana,
    s.hora_inicio,
    s.hora_fin

FROM sesion s

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

LEFT JOIN asignacion a
    ON a.id_sesion = s.id_sesion

WHERE a.id_asignacion IS NULL
  AND s.modalidad = 'PRESENCIAL'
  AND g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio;


SELECT
    cu.codigo,
    cu.nombre AS curso,
    g.numero_grupo,

    ELT(
        s.dia_semana,
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado'
    ) AS dia,

    TIME_FORMAT(
        s.hora_inicio,
        '%H:%i'
    ) AS inicio,

    TIME_FORMAT(
        s.hora_fin,
        '%H:%i'
    ) AS fin,

    g.cupo,
    s.modalidad,

    COALESCE(
        e.nombre,
        IF(
            s.modalidad = 'VIRTUAL',
            'NO REQUIERE',
            'SIN DISPONIBILIDAD'
        )
    ) AS aula

FROM sesion s

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

LEFT JOIN asignacion a
    ON a.id_sesion = s.id_sesion

LEFT JOIN espacio e
    ON e.id_espacio = a.id_espacio

WHERE g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio,
    cu.codigo;


SELECT
    COUNT(*) AS total_asignaciones
FROM asignacion;


SELECT
    e.nombre AS laboratorio,
    cu.codigo,
    cu.nombre AS curso,

    ELT(
        s.dia_semana,
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado'
    ) AS dia,

    s.hora_inicio,
    s.hora_fin

FROM asignacion a

JOIN espacio e
    ON e.id_espacio = a.id_espacio

JOIN sesion s
    ON s.id_sesion = a.id_sesion

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

WHERE e.tipo = 'LABORATORIO'
  AND g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio;


SELECT
    a.id_asignacion AS asignacion_1,
    b.id_asignacion AS asignacion_2,
    e.nombre AS espacio

FROM asignacion a

JOIN asignacion b
    ON a.id_asignacion < b.id_asignacion

JOIN sesion sa
    ON sa.id_sesion = a.id_sesion

JOIN sesion sb
    ON sb.id_sesion = b.id_sesion

JOIN grupo ga
    ON ga.id_grupo = sa.id_grupo

JOIN grupo gb
    ON gb.id_grupo = sb.id_grupo

JOIN espacio e
    ON e.id_espacio = a.id_espacio

WHERE a.id_espacio = b.id_espacio

  AND ga.id_periodo = gb.id_periodo

  AND sa.dia_semana = sb.dia_semana

  AND sa.hora_inicio < sb.hora_fin

  AND sa.hora_fin > sb.hora_inicio;


SELECT
    cu.codigo,
    cu.nombre AS curso,
    s.dia_semana,
    s.hora_inicio,
    s.hora_fin,
    s.modalidad

FROM sesion s

JOIN grupo g
    ON g.id_grupo = s.id_grupo

JOIN curso cu
    ON cu.id_curso = g.id_curso

LEFT JOIN asignacion a
    ON a.id_sesion = s.id_sesion

WHERE a.id_asignacion IS NULL
  AND s.modalidad = 'PRESENCIAL'
  AND g.id_periodo = 1

ORDER BY
    s.dia_semana,
    s.hora_inicio;


SELECT
    e.nombre AS espacio,
    e.tipo,
    e.capacidad,
    e.activo
FROM espacio e
ORDER BY e.id_espacio;
SELECT
    cu.nombre AS curso,
    c.nombre AS carrera,
    s.dia_semana,
    s.hora_inicio,
    s.hora_fin,
    e.nombre AS aula
FROM asignacion a
JOIN sesion s ON a.id_sesion = s.id_sesion
JOIN grupo g ON s.id_grupo = g.id_grupo
JOIN curso cu ON g.id_curso = cu.id_curso
JOIN carrera c ON cu.id_carrera = c.id_carrera
JOIN espacio e ON a.id_espacio = e.id_espacio
WHERE e.tipo = 'LABORATORIO'
ORDER BY s.dia_semana, s.hora_inicio;