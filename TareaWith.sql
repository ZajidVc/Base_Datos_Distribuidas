WITH R AS (
    SELECT DISTINCT c.boleta, c.clave
    FROM escuela.cursa c
    JOIN escuela.Imparte i
        ON c.clave = i.clave
    WHERE i.numEmpleado = 'P0000001'
      AND c.calif >= 6
),
WITH S AS (
    SELECT DISTINCT clave
    FROM escuela.Imparte
    WHERE numEmpleado = 'P0000001'
),
 WITH RXS AS (
    SELECT a.boleta, s.clave
    FROM (SELECT DISTINCT boleta FROM R) a
    CROSS JOIN S
),
WITH RXS_R AS (
    SELECT tc.boleta, tc.clave
    FROM RXS tc
    WHERE NOT EXISTS (
        SELECT 1
        FROM R
        WHERE tc.boleta = R.boleta
          AND tc.clave = R.clave
    )
)
SELECT boleta
FROM R
EXCEPT
SELECT boleta
FROM RXS_R;