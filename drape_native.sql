CREATE OR REPLACE FUNCTION drape_native(line geometry) RETURNS geometry AS $$
DECLARE                                                                                                      line3d geometry;
BEGIN
    RAISE NOTICE 'draping';
    WITH points2d AS
        -- Extract its points
        (SELECT (ST_DumpPoints(line)).geom AS geom),
      cells AS
        -- Get DEM elevation for each
        (SELECT p.geom AS geom, ST_Value(ned.rast, 1, p.geom) AS val
        FROM ned, points2d p
        WHERE ST_Intersects(ned.rast, p.geom)),
        -- Instantiate 3D points
      points3d AS
        (SELECT ST_SetSRID(ST_MakePoint(ST_X(line), ST_Y(line), val), ST_SRID(line)) AS geom FROM cells)
    SELECT ST_MakeLine(geom) INTO line3d FROM points3d;
    RETURN line3d;
END;
$$ LANGUAGE plpgsql;
